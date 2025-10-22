// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class CrossJoinList<T> {
  final IList<T> _list;

  const CrossJoinList._(this._list);

  static CrossJoinList<T> fromIList<T>(IList<T> list) => CrossJoinList._(list);

  CrossJoinList<T2> rmap<T2>(Func<T, T2> f) => CrossJoinList.fromIList(_list.map(f).toIList());

  static CrossJoinList<()> unit() => CrossJoinList.fromIList([()].lock);

  static CrossJoinList<Never> zero() => CrossJoinList.fromIList(const IList.empty());

  static CrossJoinList<T> of<T>(T value) => CrossJoinList.unit().rmap(constfunc(value));

  static CrossJoinList<T> empty<T>() => CrossJoinList.zero().rmap(absurd<T>);

  CrossJoinList<(T, T2)> zip<T2>(CrossJoinList<T2> other) {
    IList<(T, T2)> result = const IList.empty();

    for (final a in _list) {
      for (final a2 in other._list) {
        result = result.add((a, a2));
      }
    }

    return CrossJoinList.fromIList(result);
  }

  CrossJoinList<Either<T, T2>> altConcat<T2>(CrossJoinList<T2> other) {
    return CrossJoinList.fromIList(rmap<Either<T, T2>>(Either.left<T, T2>)._list.addAll(other.rmap(Either.right<T, T2>)._list));
  }

  CrossJoinList<Either<T, T2>> altLeftBiased<T2>(CrossJoinList<T2> other) {
    if (_list.isNotEmpty) {
      return rmap(Either.left<T, T2>);
    } else {
      return other.rmap(Either.right<T, T2>);
    }
  }

  CrossJoinList<T2> bind<T2>(Func<T, CrossJoinList<T2>> f) => CrossJoinList.fromIList(_list.expand<T2>((val) => f(val)._list).toIList());

  static CrossJoinList<IList<T>> zipAll<T>(IList<CrossJoinList<T>> list) {
    return list.fold<CrossJoinList<IList<T>>>(CrossJoinList.of<IList<T>>(IList<T>.empty()), (current, element) {
      final list = element.rmap<IList<T>>((value) => [value].lock);
      return current.zip<IList<T>>(list).rmap<IList<T>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  static CrossJoinList<(int, T)> altAllTaggedLeftBiased<T>(IList<CrossJoinList<T>> list) {
    return list.indexed.fold<CrossJoinList<(int, T)>>(CrossJoinList.empty<(int, T)>(), (current, element) {
      final (index, option) = element;
      final indexedOption = option.rmap<(int, T)>((value) => (index, value));
      return current.altLeftBiased<(int, T)>(indexedOption).rmap<(int, T)>((either) {
        return either.value();
      });
    });
  }

  static CrossJoinList<T> altAllLeftBiased<T>(IList<CrossJoinList<T>> list) {
    return altAllTaggedLeftBiased(list).rmap((tuple) => tuple.$2);
  }

  static CrossJoinList<(int, T)> altAllTaggedConcat<T>(IList<CrossJoinList<T>> list) {
    return list.indexed.fold<CrossJoinList<(int, T)>>(CrossJoinList.empty<(int, T)>(), (current, element) {
      final (index, option) = element;
      final indexedOption = option.rmap<(int, T)>((value) => (index, value));
      return current.altConcat<(int, T)>(indexedOption).rmap<(int, T)>((either) {
        return either.value();
      });
    });
  }

  static CrossJoinList<T> altAllConcat<T>(IList<CrossJoinList<T>> list) {
    return altAllTaggedConcat(list).rmap((tuple) => tuple.$2);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CrossJoinList<T>) return false;

    return _list == other._list;
  }

  @override
  int get hashCode => _list.hashCode;

  int length() => _list.length;

  Option<T> get(int index) {
    if (index < 0) {
      return Option.none();
    }

    return index >= _list.length ? Option.none() : Option.some(_list[index]);
  }
}

extension CrossJoinListMonadExtension<T> on CrossJoinList<CrossJoinList<T>> {
  CrossJoinList<T> joined() => bind(idfunc);
}
