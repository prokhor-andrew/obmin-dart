// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin_dart/obmin_dart.dart';

final class Store<A, B> {
  final A _focus;
  final Func<A, B> _store;

  A focus() => _focus;

  B peek(A focus) => _store(focus);

  const Store(this._focus, this._store);

  Store<A, B2> rmap<B2>(Func<B, B2> f) => Store(_focus, thenf(_store, f));

  B extract() => _store(_focus);

  Store<A, Store<A, B>> duplicate() => Store(_focus, constfunc(this));

  Store<A, B2> extend<B2>(Func<Store<A, B>, B2> f) => duplicate().rmap(f);
}
