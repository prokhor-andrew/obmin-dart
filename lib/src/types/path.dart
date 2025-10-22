// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class Path<K, T> {
  final IMap<IList<K>, T> _map;

  const Path._(this._map);

  static Path<K, T> fromMap<K, T>(IMap<IList<K>, T> map) => Path._(map);

  static Path<K, T> fromKeyValue<K, T>(K key, T value) => Path.fromMap<K, T>(
    {
      [key].lock: value,
    }.lock,
  );

  static Path<K, ()> unit<K>() => Path.fromMap<K, ()>({IList<K>.empty(): ()}.lock);

  static Path<K, Never> zero<K>() => Path.fromMap<K, Never>(IMap<IList<K>, Never>.empty());

  static Path<K, T> of<K, T>(T value) => Path.unit<K>().rmap(constfunc(value));

  static Path<K, T> empty<K, T>() => Path.zero<K>().rmap(absurd<T>);

  Path<K, T2> rmap<T2>(Func<T, T2> f) => Path.fromMap(_map.map((k, v) => MapEntry(k, f(v))));

  Path<K, (T, T2)> zip<T2>(Path<K, T2> other) => bind((val) => other.rmap((val2) => (val, val2)));

  Path<K, Either<T, T2>> altMerge<T2>(Path<K, T2> other) {
    final map1 = _map.map((k, v) => MapEntry(k, Either.left<T, T2>(v)));
    final map2 = other._map.map((k, v) => MapEntry(k, Either.right<T, T2>(v)));

    return Path.fromMap(map2.addAll(map1));
  }

  Path<K, Either<T, T2>> altLeftBiased<T2>(Path<K, T2> other) {
    final map1 = _map.map((k, v) => MapEntry(k, Either.left<T, T2>(v)));

    if (map1.isNotEmpty) {
      return Path.fromMap(map1);
    }

    final map2 = other._map.map((k, v) => MapEntry(k, Either.right<T, T2>(v)));

    return Path.fromMap(map2);
  }

  static Path<K, IList<T>> zipAll<K, T>(IList<Path<K, T>> list) {
    return list.fold<Path<K, IList<T>>>(Path.of<K, IList<T>>(IList<T>.empty()), (current, element) {
      final path = element.rmap<IList<T>>((value) => [value].lock);
      return current.zip<IList<T>>(path).rmap<IList<T>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  static Path<K, (int, T)> altAllTaggedMerge<K, T>(IList<Path<K, T>> list) {
    return list.indexed.fold<Path<K, (int, T)>>(Path.empty<K, (int, T)>(), (current, element) {
      final (index, option) = element;
      final indexedPath = option.rmap<(int, T)>((value) => (index, value));
      return current.altMerge<(int, T)>(indexedPath).rmap<(int, T)>((either) {
        return either.value();
      });
    });
  }

  static Path<K, T> altAllMerge<K, T>(IList<Path<K, T>> list) {
    return altAllTaggedMerge(list).rmap((tuple) => tuple.$2);
  }

  static Path<K, (int, T)> altAllTaggedLeftBiased<K, T>(IList<Path<K, T>> list) {
    return list.indexed.fold<Path<K, (int, T)>>(Path.empty<K, (int, T)>(), (current, element) {
      final (index, option) = element;
      final indexedPath = option.rmap<(int, T)>((value) => (index, value));
      return current.altLeftBiased<(int, T)>(indexedPath).rmap<(int, T)>((either) {
        return either.value();
      });
    });
  }

  static Path<K, T> altAllLeftBiased<K, T>(IList<Path<K, T>> list) {
    return altAllTaggedLeftBiased(list).rmap((tuple) => tuple.$2);
  }

  Path<K, T2> bind<T2>(Func<T, Path<K, T2>> f) {
    IMap<IList<K>, T2> result = IMap<IList<K>, T2>.empty();

    _map.forEach((k, v) {
      final path = Path.fromMap(f(v)._map.map((k2, v2) => MapEntry(k.addAll(k2), v2)));

      result = result.addAll(path._map);
    });

    return Path.fromMap(result);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Path<K, T>) return false;

    return _map == other._map;
  }

  @override
  int get hashCode => _map.hashCode;

  IMap<IList<K>, T> asMap() => _map;
}

extension PathMonadExtension<K, T> on Path<K, Path<K, T>> {
  Path<K, T> joined() {
    return bind<T>(idfunc<Path<K, T>>);
  }
}
