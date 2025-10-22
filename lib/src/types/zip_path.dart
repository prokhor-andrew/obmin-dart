// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class ZipPath<K, T> {
  final Either<T, IMap<IList<K>, T>> _mapOrNone;

  const ZipPath._(this._mapOrNone);

  ZipPath<K, T2> rmap<T2>(Func<T, T2> f) => ZipPath._(_mapOrNone.lmap(f).rmap((map) => map.map((k, v) => MapEntry(k, f(v)))));

  static ZipPath<K, ()> unit<K>() => ZipPath._(Either.left(()));

  static ZipPath<K, T> repeating<K, T>(T value) => unit<K>().rmap(constfunc(value));

  static ZipPath<K, T> fromMap<K, T>(IMap<IList<K>, T> map) => ZipPath._(Either.right(map));

  ZipPath<K, (T, T2)> zipJoinKey<T2>(ZipPath<K, T2> other, BiFunc<IList<K>, IList<K>, Option<IList<K>>> joinKeyFunc) {
    return _mapOrNone.match(
      (repeatingValue) {
        return other._mapOrNone.match(
          (repeatingValue2) {
            return ZipPath._(Either.left((repeatingValue, repeatingValue2)));
          },
          (map2) {
            return ZipPath._(Either.right(map2.map((k, value2) => MapEntry(k, (repeatingValue, value2)))));
          },
        );
      },
      (map) {
        return other._mapOrNone.match(
          (repeatingValue2) {
            return ZipPath._(Either.right(map.map((k, value) => MapEntry(k, (value, repeatingValue2)))));
          },
          (map2) {
            IMap<IList<K>, (T, T2)> result = IMap<IList<K>, (T, T2)>.empty();

            map.forEach((k, v) {
              map2.forEach((k2, v2) {
                joinKeyFunc(k, k2).runIfSome((resultKey) {
                  result = result.add(resultKey, (v, v2));
                });
              });
            });

            return ZipPath._(Either.right(result));
          },
        );
      },
    );
  }

  ZipPath<K, (T, T2)> zip<T2>(ZipPath<K, T2> other) {
    return _mapOrNone.match(
      (repeatingValue) {
        return other._mapOrNone.match(
          (repeatingValue2) {
            return ZipPath._(Either.left((repeatingValue, repeatingValue2)));
          },
          (map2) {
            return ZipPath._(Either.right(map2.map((k, value2) => MapEntry(k, (repeatingValue, value2)))));
          },
        );
      },
      (map) {
        return other._mapOrNone.match(
          (repeatingValue2) {
            return ZipPath._(Either.right(map.map((k, v) => MapEntry(k, (v, repeatingValue2)))));
          },
          (map2) {
            IMap<IList<K>, (T, T2)> result = IMap<IList<K>, (T, T2)>.empty();

            map.forEach((k, v) {
              if (!map2.containsKey(k)) {
                return;
              }

              result = result.add(k, (v, map2.get(k) as T2));
            });

            return ZipPath._(Either.right(result));
          },
        );
      },
    );
  }

  static ZipPath<K, IList<T>> zipAll<K, T>(IList<ZipPath<K, T>> list) {
    return list.fold<ZipPath<K, IList<T>>>(ZipPath.repeating<K, IList<T>>(IList<T>.empty()), (current, element) {
      final path = element.rmap<IList<T>>((value) => [value].lock);
      return current.zip<IList<T>>(path).rmap<IList<T>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  static ZipPath<K, IList<T>> zipAllJoinKey<K, T>(IList<ZipPath<K, T>> list, BiFunc<IList<K>, IList<K>, Option<IList<K>>> joinKeyFunc) {
    return list.fold<ZipPath<K, IList<T>>>(ZipPath.repeating<K, IList<T>>(IList<T>.empty()), (current, element) {
      final path = element.rmap<IList<T>>((value) => [value].lock);
      return current.zipJoinKey<IList<T>>(path, joinKeyFunc).rmap<IList<T>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  Option<T> get(IList<K> key) {
    return _mapOrNone.match(Option.some, (map) {
      if (!map.containsKey(key)) {
        return Option.none();
      }
      final value = map.get(key);
      return Option.some(value as T);
    });
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ZipPath<K, T>) return false;

    return _mapOrNone.match(
      (repeatingValue) {
        return other._mapOrNone.match(
          (repeatingValue2) => repeatingValue == repeatingValue2,
          constfunc(false),
          //
        );
      },
      (map) {
        return other._mapOrNone.match(
          constfunc(false),
          (map2) => map == map2,
          //
        );
      },
    );
  }

  @override
  int get hashCode => _mapOrNone.match((repeatingValue) => repeatingValue.hashCode, (map) => map.hashCode);

  Option<int> lengthOrRepeating() => _mapOrNone.match(constfunc(Option.none()), (map) => Option.some(map.length));

  bool isRepeating() => _mapOrNone.isLeft();

  bool isNonRepeating() => !isRepeating();
}
