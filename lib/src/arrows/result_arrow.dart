// Copyright (c) 2024 Andrii Prokhorenko
// This file is b of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class ResultArrow<E, A, B> {
  final Func<A, Result<E, B>> run;

  const ResultArrow._(this.run);

  static ResultArrow<E, A, B> fromRun<E, A, B>(Func<A, Result<E, B>> run) {
    return ResultArrow._(run);
  }

  static ResultArrow<E, A, B> fromFunc<E, A, B>(Func<A, B> f) {
    return ResultArrow.fromRun<E, A, B>((a) {
      final b = f(a);
      return ResultArrow.id<E, B>().run(b);
    });
  }

  static ResultArrow<E, A, ()> unit<E, A>() {
    return ResultArrow.fromRun<E, A, ()>(constfunc(Result.success<E, ()>(())));
  }

  static ResultArrow<E, A, A> id<E, A>() {
    return ResultArrow.fromRun<E, A, A>(Result.success<E, A>);
  }

  ResultArrow<E, A, B2> rmap<B2>(Func<B, B2> f) {
    return ResultArrow.fromRun<E, A, B2>((a) {
      return run(a).rmap<B2>(f);
    });
  }

  ResultArrow<E2, A, B> lmap<E2>(Func<E, E2> f) {
    return ResultArrow.fromRun<E2, A, B>((a) {
      return run(a).lmap<E2>(f);
    });
  }

  ResultArrow<E2, A, B2> bimap<E2, B2>(Func<E, E2> lf, Func<B, B2> rf) {
    return lmap<E2>(lf).rmap<B2>(rf);
  }

  ResultArrow<E, A2, B2> promap<A2, B2>(Func<A2, A> lf, Func<B, B2> rf) {
    return cmap<A2>(lf).rmap<B2>(rf);
  }

  ResultArrow<E, A2, B> cmap<A2>(Func<A2, A> f) {
    return ResultArrow.fromRun<E, A2, B>((a2) {
      return run(f(a2));
    });
  }

  ResultArrow<E, A, Sub> then<Sub>(ResultArrow<E, B, Sub> other) {
    return ResultArrow.fromRun<E, A, Sub>((a) {
      return run(a).bind<Sub>(other.run);
    });
  }

  ResultArrow<E, A2, B> after<A2>(ResultArrow<E, A2, A> other) {
    return other.then<B>(this);
  }

  ResultArrow<E, A, (B, B2)> zip<B2>(ResultArrow<E, A, B2> other) {
    return ResultArrow.fromRun<E, A, (B, B2)>((a) {
      return run(a).zip<B2>(other.run(a));
    });
  }

  ResultArrow<E2, A, B> lthen<E2>(ResultArrow<E2, E, B> other) {
    return ResultArrow.fromRun<E2, A, B>((a) {
      return run(a).lbind<E2>(other.run);
    });
  }

  static ResultArrow<E, A, IList<B>> zipAll<E, A, B>(IList<ResultArrow<E, A, B>> list) {
    return list.fold<ResultArrow<E, A, IList<B>>>(ResultArrow.fromRun<E, A, IList<B>>((_) => Result.success<E, IList<B>>(IList<B>.empty())), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  ResultArrow<E, (P, A), (P, B)> strong<P>() {
    return ResultArrow.fromRun<E, (P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  ResultArrow<E, Either<P, A>, Either<P, B>> choice<P>() {
    return ResultArrow.fromRun<E, Either<P, A>, Either<P, B>>((either) {
      return either.match<Result<E, Either<P, B>>>(
        (p) {
          return id<E, Either<P, B>>().run(Either.left<P, B>(p));
        },
        (a) {
          final functor = run(a);
          return functor.rmap<Either<P, B>>((b) => Either.right<P, B>(b));
        },
      );
    });
  }
}
