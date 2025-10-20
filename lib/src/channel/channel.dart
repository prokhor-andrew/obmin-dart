// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

part of 'channel_lib.dart';

final class Channel<T> {
  _ChannelState<T> _state = _IdleChannelState();

  final ChannelBufferStrategy<T> bufferStrategy;

  Channel({required this.bufferStrategy});

  ChannelTask<bool> send(T val) {
    final String id = nextId();
    final Completer<bool> completer = Completer();

    switch (_state) {
      case _IdleChannelState<T>():
        _handleBuffer(
          event: ChannelBufferAddedEvent(),
          currentArray: [ChannelBufferData._(id: id, data: val, completer: completer)],
        );
        break;
      case _AwaitingForConsumer<T>(buffer: final array):
        _handleBuffer(
          event: ChannelBufferAddedEvent(),
          currentArray: array.plus(ChannelBufferData._(id: id, data: val, completer: completer)),
        );
        break;
      case _AwaitingForProducer<T>(cur: final cur, rest: final rest):
        _state = _IdleChannelState();
        for (final element in [cur].plusMultiple(rest)) {
          element.comp.complete(Option.some(val));
        }
        completer.complete(true);
        break;
    }

    return ChannelTask(
      id: id,
      future: completer.future,
      cancel: () {
        switch (_state) {
          case _IdleChannelState<T>() || _AwaitingForProducer<T>():
            break; // do nothing, as there is no completer to be completed
          case _AwaitingForConsumer<T>(buffer: final array):
            final currentArray = array.where((data) {
              if (data.id != id) {
                return true;
              } else {
                data._completer.complete(false);
                return false;
              }
            }).toList();

            _handleBuffer(event: ChannelBufferRemovedEvent(isConsumed: false), currentArray: currentArray);
        }
      },
    );
  }

  ChannelTask<Option<T>> next() {
    final String id = nextId();
    final Completer<Option<T>> completer = Completer();

    switch (_state) {
      case _IdleChannelState<T>():
        _state = _AwaitingForProducer(cur: _ChannelConsumer(id, completer), rest: []);
        break;
      case _AwaitingForProducer<T>(cur: final cur, rest: final rest):
        _state = _AwaitingForProducer(cur: cur, rest: rest.plus(_ChannelConsumer(id, completer)));
        break;
      case _AwaitingForConsumer<T>(buffer: final array):
        array[0]._completer.complete(true);
        completer.complete(Option.some(array[0].data));
        _handleBuffer(event: ChannelBufferRemovedEvent(isConsumed: true), currentArray: array.minusFirst());
        break;
    }

    return ChannelTask(
      id: id,
      future: completer.future,
      cancel: () {
        switch (_state) {
          case _IdleChannelState<T>() || _AwaitingForConsumer<T>():
            break; // do nothing as there is no completer to complete
          case _AwaitingForProducer<T>(cur: final cur, rest: final rest):
            if (cur.id == id) {
              if (rest.isEmpty) {
                _state = _IdleChannelState();
                cur.comp.complete(Option.none());
              } else {
                _state = _AwaitingForProducer(cur: rest[0], rest: rest.minusFirst());
                cur.comp.complete(Option.none());
              }
            } else {
              final newList = rest.where((item) {
                if (item.id != id) {
                  return true;
                } else {
                  item.comp.complete(Option.none());
                  return false;
                }
              }).toList();
              _state = _AwaitingForProducer(cur: cur, rest: newList);
            }
            break;
        }
      },
    );
  }

  void _handleBuffer({required ChannelBufferEvent event, required List<ChannelBufferData<T>> currentArray}) {
    final bufferedArray = bufferStrategy.bufferReducer(currentArray.toList(), event).toList();

    final List<ChannelBufferData<T>> withoutDuplicates = bufferedArray.fold<List<ChannelBufferData<T>>>([], (partialResult, element) {
      return partialResult.contains(element) ? partialResult : partialResult.plus(element);
    }).toList();

    final set1 = Set<ChannelBufferData<T>>.from(currentArray);
    final set2 = Set<ChannelBufferData<T>>.from(withoutDuplicates);

    final difference = set1.union(set2).difference(set1.intersection(set2));
    _state = withoutDuplicates.isEmpty ? _IdleChannelState() : _AwaitingForConsumer(withoutDuplicates);

    for (final element in difference) {
      element._completer.complete(false);
    }
  }
}

sealed class _ChannelState<T> {}

final class _IdleChannelState<T> extends _ChannelState<T> {}

final class _AwaitingForProducer<T> extends _ChannelState<T> {
  final _ChannelConsumer<T> cur;
  final List<_ChannelConsumer<T>> rest;

  _AwaitingForProducer({required this.cur, required this.rest});
}

final class _AwaitingForConsumer<T> extends _ChannelState<T> {
  final List<ChannelBufferData<T>> buffer;

  _AwaitingForConsumer(this.buffer);
}

final class _ChannelConsumer<T> {
  final String id;
  final Completer<Option<T>> comp;

  _ChannelConsumer(this.id, this.comp);
}

extension _ListHelpersExtension<T> on List<T> {
  List<T> minusFirst([int count = 1]) {
    assert(count >= 0);

    if (isEmpty || count == 0) {
      return this;
    }

    if (length <= count) {
      return [];
    }

    final List<T> copy = toList();
    for (int i = 0; i < count; i++) {
      copy.removeAt(0);
    }
    return copy;
  }

  List<T> plus(T element) {
    final List<T> copy = toList();
    copy.add(element);
    return copy;
  }

  List<T> plusMultiple(List<T> elements) {
    final List<T> copy = toList();
    copy.addAll(elements);
    return copy;
  }
}

int _counter = 0;

String nextId() => 'id_${_counter++}';
