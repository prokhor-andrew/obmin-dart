// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin/obmin.dart';

final class StoreArrow<T, A, B> {
  final Func<Store<T, A>, B> run;

  const StoreArrow._(this.run);

  static StoreArrow<T, A, B> fromRun<T, A, B>(Func<Store<T, A>, B> run) => StoreArrow._(run);

  StoreArrow<T, A, B2> rmap<B2>(Func<B, B2> f) => StoreArrow.fromRun((store) => f(run(store)));

  StoreArrow<T, A2, B> cmap<A2>(Func<A2, A> f) => StoreArrow.fromRun((store) => run(store.rmap(f)));

  StoreArrow<T, A2, B2> promap<A2, B2>(Func<A2, A> lf, Func<B, B2> rf) => cmap(lf).rmap(rf);

  static StoreArrow<T, A, A> id<T, A>() => StoreArrow.fromRun((store) => store.extract());

  StoreArrow<T, A, C> then<C>(StoreArrow<T, B, C> other) => StoreArrow.fromRun((store) => other.run(store.extend(run)));
}
