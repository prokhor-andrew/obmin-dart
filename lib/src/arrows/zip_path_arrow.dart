// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class ZipPathArrow<K, A, B> {
  final Func<A, ZipPath<K, B>> run;

  const ZipPathArrow._(this.run);

  static ZipPathArrow<K, A, B> fromRun<K, A, B>(Func<A, ZipPath<K, B>> run) {
    return ZipPathArrow._(run);
  }

  static ZipPathArrow<K, A, B> fromFunc<K, A, B>(Func<A, B> f) {
    return ZipPathArrow.fromRun<K, A, B>((a) {
      final b = f(a);
      return ZipPath.repeating(b);
    });
  }

  static ZipPathArrow<K, A, ()> unit<K, A>() {
    return ZipPathArrow.fromRun<K, A, ()>(constfunc(ZipPath.unit()));
  }

  ZipPathArrow<K, A, B2> rmap<B2>(Func<B, B2> f) {
    return ZipPathArrow.fromRun<K, A, B2>((a) {
      return run(a).rmap<B2>(f);
    });
  }

  ZipPathArrow<K, A2, B> cmap<A2>(Func<A2, A> f) {
    return ZipPathArrow.fromRun<K, A2, B>((a2) {
      return run(f(a2));
    });
  }

  ZipPathArrow<K, A2, B2> promap<A2, B2>(Func<A2, A> lf, Func<B, B2> rf) {
    return cmap<A2>(lf).rmap<B2>(rf);
  }

  ZipPathArrow<K, A, (B, B2)> zip<B2>(ZipPathArrow<K, A, B2> other) {
    return ZipPathArrow.fromRun<K, A, (B, B2)>((a) {
      return run(a).zip<B2>(other.run(a));
    });
  }

  static ZipPathArrow<K, A, IList<B>> zipAll<K, A, B>(IList<ZipPathArrow<K, A, B>> list) {
    return list.fold<ZipPathArrow<K, A, IList<B>>>(ZipPathArrow.fromRun<K, A, IList<B>>((_) => ZipPath.repeating(IList<B>.empty())), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  ZipPathArrow<K, A, (B, B2)> zipJoinKey<B2>(ZipPathArrow<K, A, B2> other, BiFunc<IList<K>, IList<K>, Option<IList<K>>> joinKeyFunc) {
    return ZipPathArrow.fromRun<K, A, (B, B2)>((a) {
      return run(a).zipJoinKey<B2>(other.run(a), joinKeyFunc);
    });
  }

  static ZipPathArrow<K, A, IList<B>> zipAllJoinKey<K, A, B>(IList<ZipPathArrow<K, A, B>> list, BiFunc<IList<K>, IList<K>, Option<IList<K>>> joinKeyFunc) {
    return list.fold<ZipPathArrow<K, A, IList<B>>>(ZipPathArrow.fromRun<K, A, IList<B>>((_) => ZipPath.repeating(IList<B>.empty())), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zipJoinKey<IList<B>>(arrow, joinKeyFunc).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  ZipPathArrow<K, (P, A), (P, B)> strong<P>() {
    return ZipPathArrow.fromRun<K, (P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  ZipPathArrow<K, Either<P, A>, Either<P, B>> choice<P>() {
    return ZipPathArrow.fromRun<K, Either<P, A>, Either<P, B>>((either) {
      return either
          .lmap(Either.left<P, B>)
          .lmap(ZipPath.repeating<K, Either<P, B>>)
          .rmap(run)
          .rmap((list) => list.rmap(Either.right<P, B>)) //
          .value();
    });
  }
}
