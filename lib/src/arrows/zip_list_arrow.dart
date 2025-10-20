// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin_dart/obmin_dart.dart';

final class ZipListArrow<A, B> {
  final Func<A, ZipList<B>> run;

  const ZipListArrow._(this.run);

  static ZipListArrow<A, B> fromRun<A, B>(Func<A, ZipList<B>> run) {
    return ZipListArrow._(run);
  }

  static ZipListArrow<A, B> fromFunc<A, B>(Func<A, B> f) {
    return ZipListArrow.fromRun<A, B>((a) {
      final b = f(a);
      return ZipList.repeating(b);
    });
  }

  static ZipListArrow<A, ()> unit<A>() {
    return ZipListArrow.fromRun<A, ()>(constfunc(ZipList.unit()));
  }

  ZipListArrow<A, B2> rmap<B2>(Func<B, B2> f) {
    return ZipListArrow.fromRun<A, B2>((a) {
      return run(a).rmap<B2>(f);
    });
  }

  ZipListArrow<A2, B> cmap<A2>(Func<A2, A> f) {
    return ZipListArrow.fromRun<A2, B>((a2) {
      return run(f(a2));
    });
  }

  ZipListArrow<A2, B2> promap<A2, B2>(Func<A2, A> lf, Func<B, B2> rf) {
    return cmap<A2>(lf).rmap<B2>(rf);
  }

  ZipListArrow<A, (B, B2)> zip<B2>(ZipListArrow<A, B2> other) {
    return ZipListArrow.fromRun<A, (B, B2)>((a) {
      return run(a).zip<B2>(other.run(a));
    });
  }

  static ZipListArrow<A, IList<B>> zipAll<A, B>(IList<ZipListArrow<A, B>> list) {
    return list.fold<ZipListArrow<A, IList<B>>>(ZipListArrow.fromRun<A, IList<B>>((_) => ZipList.repeating(IList<B>.empty())), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  ZipListArrow<(P, A), (P, B)> strong<P>() {
    return ZipListArrow.fromRun<(P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  ZipListArrow<Either<P, A>, Either<P, B>> choice<P>() {
    return ZipListArrow.fromRun<Either<P, A>, Either<P, B>>((either) {
      return either
          .lmap(Either.left<P, B>)
          .lmap(ZipList.repeating)
          .rmap(run)
          .rmap((list) => list.rmap(Either.right<P, B>)) //
          .value();
    });
  }
}
