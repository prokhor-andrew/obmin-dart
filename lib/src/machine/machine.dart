// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart' hide Output;
import 'package:obmin/obmin.dart';

final class Machine<Input, Output> {
  final ChannelBufferStrategy<Input>? inputBufferStrategy;
  final ChannelBufferStrategy<Output>? outputBufferStrategy;

  final (
    Future<void> Function(ChannelTask<bool> Function(Output output)? callback) onChange,
    Future<void> Function(Input input) onProcess,
    //
  )
  Function()
  onCreate;

  const Machine({this.inputBufferStrategy, this.outputBufferStrategy, required this.onCreate});

  Process run({
    ChannelBufferStrategy<Input>? inputBufferStrategy,
    ChannelBufferStrategy<Output>? outputBufferStrategy,
    required Future<void> Function(ChannelTask<bool> Function(Input input)? sender) onChange,
    required Future<void> Function(Output output) onConsume,
  }) {
    final onChangeExternal = onChange;

    final ChannelBufferStrategy<Output> actualOutputBufferStrategy = this.outputBufferStrategy ?? outputBufferStrategy ?? ChannelBufferStrategy.defaultStrategy(id: "default");
    final ChannelBufferStrategy<Input> actualInputBufferStrategy = this.inputBufferStrategy ?? inputBufferStrategy ?? ChannelBufferStrategy.defaultStrategy(id: "default");

    final _Channel<Input> inputChannel = _Channel(bufferStrategy: actualInputBufferStrategy);

    final _Channel<Output> outputChannel = _Channel(bufferStrategy: actualOutputBufferStrategy);

    bool isCancelled = false;
    ChannelTask<Option<Input>>? inputTask;
    ChannelTask<Option<Output>>? outputTask;

    Future(() async {
      if (isCancelled) {
        return;
      }

      final (onChangeInternal, onProcess) = onCreate();

      final future = Future.wait([
        Future(() async {
          while (true) {
            if (isCancelled) {
              break;
            }
            final ChannelTask<Option<Input>> task = inputChannel.next();
            inputTask = task;
            final value = await task.future;
            if (value.isNone()) {
              break;
            }
            await onProcess(value.force());
          }
        }),
        Future(() async {
          while (true) {
            if (isCancelled) {
              break;
            }
            final ChannelTask<Option<Output>> task = outputChannel.next();
            outputTask = task;
            final value = await task.future;
            if (value.isNone()) {
              break;
            }
            await onConsume(value.force());
          }
        }),
      ]);

      await Future.wait([onChangeInternal(outputChannel.send), onChangeExternal(inputChannel.send)]);

      if (!isCancelled) {
        await future;
      }

      await Future.wait([onChangeInternal(null), onChangeExternal(null)]);
    });

    return Process._(
      cancel: () {
        isCancelled = true;
        inputTask?.cancel();
        inputTask = null;
        outputTask?.cancel();
        outputTask = null;
      },
    );
  }

  static Machine<Input, Output> fromResource<Obj, Input, Output>({
    required Obj Function() onCreate,
    required Future<void> Function(Obj object, ChannelTask<bool> Function(Output output)? callback) onChange,
    required Future<void> Function(Obj object, Input input) onProcess,
    ChannelBufferStrategy<Input>? inputBufferStrategy,
    ChannelBufferStrategy<Output>? outputBufferStrategy,
  }) {
    return Machine<Input, Output>(
      inputBufferStrategy: inputBufferStrategy,
      outputBufferStrategy: outputBufferStrategy,
      onCreate: () {
        final Obj object = onCreate();

        return (
          (callback) async {
            await onChange(object, callback);
          },
          (input) async {
            await onProcess(object, input);
          },
        );
      },
    );
  }

  static Machine<ExtTrigger, ExtEffect> fromMealy<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect>({
    required Future<Mealy<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect>> Function() onCreateMealy,
    required Future<void> Function(State state) onDestroyMealy,
    bool shouldWaitOnEffects = true,
    ChannelBufferStrategy<ExtTrigger>? inputBufferStrategy,
    ChannelBufferStrategy<ExtEffect>? outputBufferStrategy,
    ChannelBufferStrategy<Either<IntTrigger, ExtTrigger>>? internalBufferStrategy,
  }) {
    return Machine.fromResource<_MealyHolder<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect>, ExtTrigger, ExtEffect>(
      inputBufferStrategy: inputBufferStrategy,
      outputBufferStrategy: outputBufferStrategy,
      onCreate: () {
        return _MealyHolder(bufferStrategy: internalBufferStrategy, onCreate: onCreateMealy, onDestroy: onDestroyMealy, shouldWaitOnEffects: shouldWaitOnEffects);
      },
      onChange: (object, callback) async {
        await object.onChange(callback);
      },
      onProcess: (object, input) async {
        await object.onProcess(input);
      },
    );
  }

  static Machine<Never, T> fromProducer<Obj, T>({
    required Obj Function(void Function(T response) callback) onStart,
    required void Function(Obj object) onStop,
    ChannelBufferStrategy<T>? bufferStrategy,
  }) {
    return Machine.fromResource<_ProducerHolder<Obj>, Never, T>(
      onCreate: () {
        return _ProducerHolder<Obj>();
      },
      onChange: (object, callback) async {
        if (callback != null) {
          object.object = onStart((output) async {
            await callback(output).future;
          });
        } else {
          onStop(object.object as Obj);
          object.object = null;
        }
      },
      onProcess: (object, input) async {
        // do nothing
      },
      outputBufferStrategy: bufferStrategy,
    );
  }

  static Machine<Never, Res> fromStream<Res>(Stream<Res> Function() stream) {
    return Machine.fromProducer<StreamSubscription<Res>, Res>(
      onStart: (callback) {
        return stream().listen(callback);
      },
      onStop: (sub) {
        sub.cancel();
      },
    );
  }

  static Machine<Never, Res> fromFuture<Res>(Future<Res> Function() future) {
    return Machine.fromStream<Res>(() {
      return future().asStream();
    });
  }

  Machine<R, Output> cmap<R>(
    Input Function(R input) function, {
    bool shouldWaitOnEffects = false,
    ChannelBufferStrategy<R>? inputBufferStrategy,
    ChannelBufferStrategy<Output>? outputBufferStrategy,
    ChannelBufferStrategy<Either<Output, R>>? internalBufferStrategy,
  }) {
    return Machine.fromMealy<(), Output, Input, R, Output>(
      inputBufferStrategy: inputBufferStrategy,
      outputBufferStrategy: outputBufferStrategy,
      internalBufferStrategy: internalBufferStrategy,
      onCreateMealy: () async {
        Plan<(), Output, Input, R, Output> outline() {
          return Plan.create(
            state: (),
            transit: (state, trigger) {
              return trigger.match(
                (value) {
                  return PlanTransition(outline(), effects: [Either.right<Input, Output>(value)].lock);
                },
                (value) {
                  return PlanTransition(outline(), effects: [Either.left<Input, Output>(function(value))].lock);
                },
              );
            },
          );
        }

        return outline().asMealy({"key": this}.lock);
      },
      onDestroyMealy: (_) async {},
      shouldWaitOnEffects: shouldWaitOnEffects,
    );
  }

  Machine<Input, R> rmap<R>(
    R Function(Output output) function, {
    bool shouldWaitOnEffects = false,
    ChannelBufferStrategy<Input>? inputBufferStrategy,
    ChannelBufferStrategy<R>? outputBufferStrategy,
    ChannelBufferStrategy<Either<Output, Input>>? internalBufferStrategy,
  }) {
    return Machine.fromMealy<(), Output, Input, Input, R>(
      inputBufferStrategy: inputBufferStrategy,
      outputBufferStrategy: outputBufferStrategy,
      internalBufferStrategy: internalBufferStrategy,
      onCreateMealy: () async {
        Plan<(), Output, Input, Input, R> outline() {
          return Plan.create(
            state: (),
            transit: (state, trigger) {
              return trigger.match(
                (value) {
                  return PlanTransition(outline(), effects: [Either.right<Input, R>(function(value))].lock);
                },
                (value) {
                  return PlanTransition(outline(), effects: [Either.left<Input, R>(value)].lock);
                },
              );
            },
          );
        }

        return outline().asMealy({"key": this}.lock);
      },
      onDestroyMealy: (_) async {},
      shouldWaitOnEffects: shouldWaitOnEffects,
    );
  }

  static Machine<Input, Output> fromPool<Input, Output, Helper>({
    required Future<Helper> Function() onCreateHelper,
    required Future<void> Function(Helper helper) onDestroyHelper,
    required IMap<String, Machine<Never, Output>> Function(Helper helper) initial,
    required IMap<String, Machine<Never, Output>> Function(Helper helper, Input input) map,
    bool shouldWaitOnEffects = true,
    ChannelBufferStrategy<Input>? inputBufferStrategy,
    ChannelBufferStrategy<Output>? outputBufferStrategy,
    ChannelBufferStrategy<Either<Output, Input>>? internalBufferStrategy,
  }) {
    Mealy<Helper, Output, Never, Input, Output> config(Helper helper, IMap<String, Machine<Never, Output>> machines) {
      return Mealy.create(
        state: helper,
        machines: machines,
        transit: (state, machines, trigger) {
          return trigger.match(
            (value) {
              return MealyTransition(config(state, machines), effects: [Either.right<Never, Output>(value)].lock);
            },
            (value) {
              return MealyTransition(config(state, map(state, value)));
            },
          );
        },
      );
    }

    return Machine.fromMealy(
      shouldWaitOnEffects: shouldWaitOnEffects,
      inputBufferStrategy: inputBufferStrategy,
      outputBufferStrategy: outputBufferStrategy,
      internalBufferStrategy: internalBufferStrategy,
      onCreateMealy: () async {
        final helper = await onCreateHelper();
        final initialMachines = initial(helper);
        return config(helper, initialMachines);
      },
      onDestroyMealy: (helper) async {
        await onDestroyHelper(helper);
      },
    );
  }

  static Machine<State, Endo<State>> fromPoolX<State, Helper>({
    required Future<Helper> Function() onCreateHelper,
    required Future<void> Function(Helper helper) onDestroyHelper,
    required State initial,
    required PathArrow<String, (Helper, State), Machine<Never, Endo<State>>> arrow,
    bool isDistinctUntilChangedOn = true,
    bool shouldWaitOnEffects = true,
    ChannelBufferStrategy<State>? inputBufferStrategy,
    ChannelBufferStrategy<Endo<State>>? outputBufferStrategy,
    ChannelBufferStrategy<Either<Endo<State>, State>>? internalBufferStrategy,
  }) {
    IMap<String, Machine<Never, Endo<State>>> mapping(Helper helper, State state) {
      final map = arrow.run((helper, state)).asMap();
      return map.map((key, value) => MapEntry(key.join("/"), value));
    }

    final machine = Machine.fromPool<State, Endo<State>, Helper>(
      onCreateHelper: onCreateHelper,
      onDestroyHelper: onDestroyHelper,
      initial: (helper) {
        return mapping(helper, initial);
      },
      map: mapping,
      shouldWaitOnEffects: shouldWaitOnEffects,
      inputBufferStrategy: inputBufferStrategy,
      outputBufferStrategy: outputBufferStrategy,
      internalBufferStrategy: internalBufferStrategy,
    );
    return isDistinctUntilChangedOn ? machine.distinctUntilChangedInput(shouldWaitOnEffects: false) : machine;
  }

  Machine<Input, Output> distinctUntilChangedInput({
    bool shouldWaitOnEffects = false,
    ChannelBufferStrategy<Input>? inputBufferStrategy,
    ChannelBufferStrategy<Output>? outputBufferStrategy,
    ChannelBufferStrategy<Either<Output, Input>>? internalBufferStrategy,
  }) {
    Plan<Option<Input>, Output, Input, Input, Output> outline(Option<Input> state) {
      return Plan.create(
        state: state,
        transit: (state, trigger) {
          return trigger.match(
            (value) {
              return PlanTransition(outline(state), effects: [Either.right<Input, Output>(value)].lock);
            },
            (value) {
              return PlanTransition(
                outline(Option.some(value)),
                effects: state
                    .rmap<IList<Either<Input, Output>>>((state) {
                      return state == value ? const IList.empty() : [Either.left<Input, Output>(value)].lock;
                    })
                    .valueOr([Either.left<Input, Output>(value)].lock),
              );
            },
          );
        },
      );
    }

    return Machine.fromMealy(
      onCreateMealy: () async {
        return outline(Option.none()).asMealy({"key": this}.lock);
      },
      onDestroyMealy: (_) async {},
      shouldWaitOnEffects: shouldWaitOnEffects,
      inputBufferStrategy: inputBufferStrategy,
      outputBufferStrategy: outputBufferStrategy,
      internalBufferStrategy: internalBufferStrategy,
    );
  }

  Machine<Input, Output> distinctUntilChangedOutput({
    required bool shouldWaitOnEffects,
    ChannelBufferStrategy<Input>? inputBufferStrategy,
    ChannelBufferStrategy<Output>? outputBufferStrategy,
    ChannelBufferStrategy<Either<Output, Input>>? internalBufferStrategy,
  }) {
    Plan<Option<Output>, Output, Input, Input, Output> outline(Option<Output> state) {
      return Plan.create(
        state: state,
        transit: (state, trigger) {
          return trigger.match(
            (value) {
              return PlanTransition(
                outline(Option.some(value)),
                effects: state
                    .rmap<IList<Either<Input, Output>>>((state) {
                      return state == value ? const IList.empty() : [Either.right<Input, Output>(value)].lock;
                    })
                    .valueOr([Either.right<Input, Output>(value)].lock),
              );
            },
            (value) {
              return PlanTransition(outline(state), effects: [Either.left<Input, Output>(value)].lock);
            },
          );
        },
      );
    }

    return Machine.fromMealy(
      onCreateMealy: () async {
        return outline(Option.none()).asMealy({"key": this}.lock);
      },
      onDestroyMealy: (_) async {},
      shouldWaitOnEffects: shouldWaitOnEffects,
      inputBufferStrategy: inputBufferStrategy,
      outputBufferStrategy: outputBufferStrategy,
      internalBufferStrategy: internalBufferStrategy,
    );
  }
}

final class Process {
  final void Function() _cancel;

  const Process._({required void Function() cancel}) : _cancel = cancel;

  void cancel() {
    _cancel();
  }
}

final class _ProducerHolder<Obj> {
  Obj? object;
}

final class _MealyHolder<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> {
  final Future<Mealy<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect>> Function() _onCreate;
  final Future<void> Function(State state) _onDestroy;
  final bool shouldWaitOnEffects;

  bool _isCancelled = false;

  ChannelTask<bool> Function(ExtEffect)? _callback;

  IMap<String, Process> _processes = const IMap.empty();
  final Map<String, ChannelTask<bool> Function(IntEffect)> _senders = {};

  final _Channel<Either<IntTrigger, ExtTrigger>> _channel;
  ChannelTask<Option<Either<IntTrigger, ExtTrigger>>>? _task;

  late State _state;

  MealyTransition<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> Function(Either<IntTrigger, ExtTrigger>)? _transit;

  _MealyHolder({
    ChannelBufferStrategy<Either<IntTrigger, ExtTrigger>>? bufferStrategy,
    required Future<Mealy<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect>> Function() onCreate,
    required Future<void> Function(State state) onDestroy,
    required this.shouldWaitOnEffects,
  }) : _onCreate = onCreate,
       _onDestroy = onDestroy,
       _channel = _Channel(bufferStrategy: bufferStrategy ?? ChannelBufferStrategy.defaultStrategy(id: "default"));

  Future<void> onChange(ChannelTask<bool> Function(ExtEffect effect)? callback) async {
    _callback = callback;

    if (callback != null) {
      final state = await _onCreate();
      _state = state.state;
      _transit = state.transit;

      _processes = state.machines.map((key, machine) {
        return MapEntry(
          key,
          machine.run(
            onChange: (sender) async {
              if (sender != null) {
                _senders[key] = sender;
              } else {
                _senders.remove(key);
              }
            },
            onConsume: (event) async {
              await _channel.send(Either.left(event)).future;
            },
          ),
        );
      });

      Future(() async {
        while (true) {
          if (_isCancelled) {
            break;
          }
          final ChannelTask<Option<Either<IntTrigger, ExtTrigger>>> task = _channel.next();
          _task = task;
          final value = await task.future;

          if (value.isNone()) {
            break;
          }

          await _handle(value.force());
        }
      });
    } else {
      _isCancelled = true;
      _task?.cancel();
      _task = null;
      _transit = null;
      for (final process in _processes.entries) {
        process.value.cancel();
      }
      _processes = const IMap.empty();

      await _onDestroy(_state);
    }
  }

  Future<void> onProcess(ExtTrigger input) async {
    await _channel.send(Either.right(input)).future;
  }

  Future<void> _handle(Either<IntTrigger, ExtTrigger> event) async {
    final transit = _transit;
    if (transit == null) {
      return;
    }
    final transition = transit(event);

    final resultingMachines = transition.mealy.machines;

    final machinesToAdd = resultingMachines.where((machineKey, machine) {
      return _processes.where((processKey, process) {
        return processKey == machineKey;
      }).isEmpty;
    });

    final processesToRemove = _processes.where((processKey, process) {
      return resultingMachines.where((machineKey, machine) {
        return machineKey == processKey;
      }).isEmpty;
    });

    final processesToKeep = _processes.where((processKey, process) {
      return machinesToAdd.where((machineKey, machine) {
            return machineKey == processKey;
          }).isEmpty &&
          processesToRemove.where((processToRemoveKey, processToRemove) {
            return processToRemoveKey == processKey;
          }).isEmpty;
    });

    for (final process in processesToRemove.entries) {
      process.value.cancel();
    }

    final processesToAdd = machinesToAdd.map((key, machine) {
      return MapEntry(
        key,
        machine.run(
          onChange: (sender) async {
            if (sender != null) {
              _senders[key] = sender;
            } else {
              _senders.remove(key);
            }
          },
          onConsume: (output) async {
            await _channel.send(Either.left(output)).future;
          },
        ),
      );
    });

    _processes = processesToAdd.addAll(processesToKeep);
    _state = transition.mealy.state;
    _transit = transition.mealy.transit;

    final effects = transition.effects;

    final effectsFuture = Future.wait<void>([
      Future(() async {
        for (final effect in effects) {
          await effect.match((_) => Future.sync(() {}), (value) async {
            final callback = _callback;
            if (callback != null) {
              await callback(value).future;
            }
          });
        }
      }),
      Future.wait(
        _senders.values.map((sender) {
          return Future(() async {
            for (final effect in effects) {
              await effect.match((value) async {
                await sender(value).future;
              }, (_) => Future.sync(() {}));
            }
          });
        }),
      ),
    ]);

    if (shouldWaitOnEffects) {
      await effectsFuture;
    }
  }
}

extension _OptionForce<A> on Option<A> {
  A force() {
    return match<A>(() => throw "Option.none is being forcefully unwrapped", idfunc);
  }
}

// CHANNEL HELPER

final class _Channel<T> {
  _ChannelState<T> _state = _IdleChannelState();

  final ChannelBufferStrategy<T> bufferStrategy;

  _Channel({required this.bufferStrategy});

  ChannelTask<bool> send(T val) {
    final String id = _nextId();
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

    return ChannelTask._(
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
    final String id = _nextId();
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

    return ChannelTask._(
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

sealed class _ChannelState<T> {
  const _ChannelState();
}

final class _IdleChannelState<T> extends _ChannelState<T> {
  const _IdleChannelState();
}

final class _AwaitingForProducer<T> extends _ChannelState<T> {
  final _ChannelConsumer<T> cur;
  final List<_ChannelConsumer<T>> rest;

  const _AwaitingForProducer({required this.cur, required this.rest});
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

String _nextId() => 'id_${_counter++}';

final class ChannelBufferData<T> {
  final String id;
  final T data;
  final Completer<bool> _completer;

  const ChannelBufferData._({required this.id, required this.data, required Completer<bool> completer}) : _completer = completer;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChannelBufferData<T> && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChannelBufferData<$T>{ id=$id _ data=$data }';
  }
}

sealed class ChannelBufferEvent {
  const ChannelBufferEvent();

  bool get isAdded => switch (this) {
    ChannelBufferAddedEvent() => true,
    ChannelBufferRemovedEvent() => false,
  };

  bool get isRemoved => !isAdded;

  @override
  String toString() {
    switch (this) {
      case ChannelBufferAddedEvent():
        return "ChannelBufferAddedEvent";
      case ChannelBufferRemovedEvent(isConsumed: final isConsumed):
        return "ChannelBufferRemovedEvent{ ${isConsumed ? "consumed" : "cancelled"} }";
    }
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChannelBufferEvent && runtimeType == other.runtimeType && isAdded == other.isAdded;

  @override
  int get hashCode => isAdded.hashCode;
}

final class ChannelBufferAddedEvent extends ChannelBufferEvent {
  const ChannelBufferAddedEvent();
}

final class ChannelBufferRemovedEvent extends ChannelBufferEvent {
  final bool isConsumed;

  const ChannelBufferRemovedEvent({required this.isConsumed});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || super == other && other is ChannelBufferRemovedEvent && runtimeType == other.runtimeType && isAdded == other.isAdded && isConsumed == other.isConsumed;

  @override
  int get hashCode => super.hashCode ^ isConsumed.hashCode;
}

final class ChannelBufferStrategy<T> {
  final String id;
  final List<ChannelBufferData<T>> Function(List<ChannelBufferData<T>> data, ChannelBufferEvent event) bufferReducer;

  const ChannelBufferStrategy({required this.id, required this.bufferReducer});

  static ChannelBufferStrategy<T> defaultStrategy<T>({required String id}) {
    return ChannelBufferStrategy<T>(
      id: id,
      bufferReducer: (data, event) {
        return data;
      },
    );
  }

  @override
  String toString() {
    return "ChannelBufferStrategy<$T>{ id=$id }";
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChannelBufferStrategy<T> && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

final class ChannelTask<T> {
  final String id;
  final Future<T> future;
  final void Function() cancel;

  const ChannelTask._({required this.id, required this.future, required this.cancel});

  @override
  String toString() {
    return "$ChannelTask<$T> id=$id";
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChannelTask<T> && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
