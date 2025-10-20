// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'dart:math';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin_dart/obmin_dart.dart';

final class ZipList<T> {
  final Either<T, IList<T>> _listOrNone;

  const ZipList._(this._listOrNone);

  ZipList<T2> rmap<T2>(Func<T, T2> f) => ZipList._(_listOrNone.lmap(f).rmap((list) => list.rmap(f)));

  static ZipList<()> unit() => ZipList._(Either.left(()));

  static ZipList<T> repeating<T>(T value) => unit().rmap(constfunc(value));

  static ZipList<T> fromList<T>(IList<T> list) => ZipList._(Either.right(list));

  ZipList<(T, T2)> zip<T2>(ZipList<T2> other) {
    return _listOrNone.match(
      (repeatingValue) {
        return other._listOrNone.match(
          (repeatingValue2) {
            return ZipList._(Either.left((repeatingValue, repeatingValue2)));
          },
          (list2) {
            return ZipList._(Either.right(list2.rmap((value2) => (repeatingValue, value2))));
          },
        );
      },
      (list) {
        return other._listOrNone.match(
          (repeatingValue2) {
            return ZipList._(Either.right(list.rmap((value) => (value, repeatingValue2))));
          },
          (list2) {
            IList<(T, T2)> result = IList<(T, T2)>.empty();
            final int len = min(list.length, list2.length);
            for (int i = 0; i < len; i++) {
              final value1 = list[i];
              final value2 = list2[i];

              result = result.add((value1, value2));
            }

            return ZipList._(Either.right(result));
          },
        );
      },
    );
  }

  static ZipList<IList<T>> zipAll<T>(IList<ZipList<T>> list) {
    return list.fold<ZipList<IList<T>>>(ZipList.repeating<IList<T>>(IList<T>.empty()), (current, element) {
      final path = element.rmap<IList<T>>((value) => [value].lock);
      return current.zip<IList<T>>(path).rmap<IList<T>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  Option<T> get(int index) {
    if (index < 0) {
      return Option.none();
    }

    return _listOrNone.match(Option.some, (list) {
      if (index >= list.length) {
        return Option.none();
      }
      return Option.some(list[index]);
    });
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ZipList<T>) return false;

    return _listOrNone.match(
      (repeatingValue) {
        return other._listOrNone.match(
          (repeatingValue2) => repeatingValue == repeatingValue2,
          constfunc(false),
          //
        );
      },
      (list) {
        return other._listOrNone.match(
          constfunc(false),
          (list2) => list == list2,
          //
        );
      },
    );
  }

  @override
  int get hashCode => _listOrNone.match((repeatingValue) => repeatingValue.hashCode, (list) => list.hashCode);

  Option<int> lengthOrRepeating() => _listOrNone.match(constfunc(Option.none()), (list) => Option.some(list.length));

  bool isRepeating() => _listOrNone.isLeft();

  bool isNonRepeating() => !isRepeating();
}
