// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin_dart/obmin_dart.dart';

final class WriterArrow<E, A, B> {
  final Func<A, Writer<E, B>> run;

  const WriterArrow._(this.run);

  static WriterArrow<E, A, B> fromRun<E, A, B>(Func<A, Writer<E, B>> run) {
    return WriterArrow._(run);
  }

  static WriterArrow<E, A, B> fromFunc<E, A, B>(Func<A, B> f) {
    return WriterArrow.fromRun<E, A, B>((a) {
      final b = f(a);
      return WriterArrow.id<E, B>().run(b);
    });
  }

  static WriterArrow<E, A, ()> unit<E, A>() {
    return WriterArrow.fromRun<E, A, ()>(constfunc<A, Writer<E, ()>>(Writer(IList<E>.empty(), ())));
  }

  WriterArrow<E, A, B2> rmap<B2>(Func<B, B2> f) {
    return WriterArrow.fromRun<E, A, B2>((a) {
      return run(a).rmap<B2>(f);
    });
  }

  WriterArrow<E2, A, B> lmap<E2>(Func<E, E2> f) {
    return WriterArrow.fromRun<E2, A, B>((a) {
      return run(a).lmap<E2>(f);
    });
  }

  WriterArrow<E, A2, B> cmap<A2>(Func<A2, A> f) {
    return WriterArrow.fromRun<E, A2, B>((a2) {
      return run(f(a2));
    });
  }

  WriterArrow<E2, A, B2> bimap<E2, B2>(Func<E, E2> lf, Func<B, B2> rf) {
    return lmap<E2>(lf).rmap<B2>(rf);
  }

  WriterArrow<E, A2, B2> promap<A2, B2>(Func<A2, A> lf, Func<B, B2> rf) {
    return cmap<A2>(lf).rmap<B2>(rf);
  }

  static WriterArrow<E, A, A> id<E, A>() {
    return WriterArrow.fromRun<E, A, A>(Writer.of<E, A>);
  }

  WriterArrow<E, A, Sub> then<Sub>(WriterArrow<E, B, Sub> other) {
    return WriterArrow.fromRun<E, A, Sub>((a) {
      return run(a).bind<Sub>(other.run);
    });
  }

  WriterArrow<E, A2, B> after<A2>(WriterArrow<E, A2, A> other) {
    return other.then<B>(this);
  }

  WriterArrow<E, A, (B, B2)> zip<B2>(WriterArrow<E, A, B2> other) {
    return WriterArrow.fromRun<E, A, (B, B2)>((a) {
      return run(a).zip<B2>(other.run(a));
    });
  }

  static WriterArrow<E, A, IList<B>> zipAll<E, A, B>(IList<WriterArrow<E, A, B>> list) {
    return list.fold<WriterArrow<E, A, IList<B>>>(WriterArrow.fromRun<E, A, IList<B>>((_) => Writer.of<E, IList<B>>(IList<B>.empty())), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  WriterArrow<E, (P, A), (P, B)> strong<P>() {
    return WriterArrow.fromRun<E, (P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  WriterArrow<E, Either<P, A>, Either<P, B>> choice<P>() {
    return WriterArrow.fromRun<E, Either<P, A>, Either<P, B>>((either) {
      return either.match<Writer<E, Either<P, B>>>(
        (p) {
          return WriterArrow.id<E, Either<P, B>>().run(Either.left<P, B>(p));
        },
        (a) {
          final functor = run(a);
          return functor.rmap<Either<P, B>>((b) => Either.right<P, B>(b));
        },
      );
    });
  }
}
