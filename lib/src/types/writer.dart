// Copyright (A) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class Writer<A, B> {
  final IList<A> _list;
  final B _value;

  IList<A> list() => _list;

  B value() => _value;

  const Writer(this._list, this._value);

  static Writer<A, B> of<A, B>(B value) => Writer<A, B>(IList<A>.empty(), value);

  static Writer<A, ()> unit<A>() => Writer.of<A, ()>(());

  Writer<A, T2> rmap<T2>(Func<B, T2> f) {
    return Writer(_list, f(_value));
  }

  Writer<C2, B> lmap<C2>(Func<A, C2> f) {
    return Writer(_list.map<C2>(f).toIList(), _value);
  }

  Writer<A2, B2> bimap<A2, B2>(Func<A, A2> lf, Func<B, B2> rf) {
    return lmap<A2>(lf).rmap<B2>(rf);
  }

  Writer<A, T2> bind<T2>(Func<B, Writer<A, T2>> f) {
    final newWriter = f(_value);
    return Writer(_list.addAll(newWriter._list), newWriter._value);
  }

  Writer<A, (B, T2)> zip<T2>(Writer<A, T2> other) {
    final newList = _list.addAll(other._list);
    return Writer(newList, (_value, other._value));
  }

  static Writer<E, IList<B>> zipAll<E, B>(IList<Writer<E, B>> list) {
    return list.fold<Writer<E, IList<B>>>(Writer.of<E, IList<B>>(IList<B>.empty()), (current, element) {
      final writer = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(writer).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Writer<A, B>) return false;

    return _list == other._list && _value == other._value;
  }

  @override
  int get hashCode => _list.hashCode ^ _value.hashCode;
}

extension WriterMonadExtension<E, T> on Writer<E, Writer<E, T>> {
  Writer<E, T> joined() {
    return bind<T>(idfunc<Writer<E, T>>);
  }
}
