// Copyright (c) 2024 Andrii Prokhorenko
// This file is b of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class EitherArrow<E, A, B> {
  final Func<A, Either<E, B>> run;

  const EitherArrow._(this.run);

  static EitherArrow<E, A, B> fromRun<E, A, B>(Func<A, Either<E, B>> run) {
    return EitherArrow._(run);
  }

  static EitherArrow<E, A, B> fromFunc<E, A, B>(Func<A, B> f) {
    return EitherArrow.fromRun<E, A, B>((a) {
      final b = f(a);
      return EitherArrow.id<E, B>().run(b);
    });
  }

  static EitherArrow<E, A, ()> unit<E, A>() {
    return EitherArrow.fromRun<E, A, ()>(constfunc(Either.right<E, ()>(())));
  }

  static EitherArrow<E, A, A> id<E, A>() {
    return EitherArrow.fromRun<E, A, A>(Either.right<E, A>);
  }

  EitherArrow<E, A, B2> rmap<B2>(Func<B, B2> f) {
    return EitherArrow.fromRun<E, A, B2>((a) {
      return run(a).rmap<B2>(f);
    });
  }

  EitherArrow<E2, A, B> lmap<E2>(Func<E, E2> f) {
    return EitherArrow.fromRun<E2, A, B>((a) {
      return run(a).lmap<E2>(f);
    });
  }

  EitherArrow<E2, A, B2> bimap<E2, B2>(Func<E, E2> lf, Func<B, B2> rf) {
    return lmap<E2>(lf).rmap<B2>(rf);
  }

  EitherArrow<E, A2, B2> promap<A2, B2>(Func<A2, A> lf, Func<B, B2> rf) {
    return cmap<A2>(lf).rmap<B2>(rf);
  }

  EitherArrow<E, A2, B> cmap<A2>(Func<A2, A> f) {
    return EitherArrow.fromRun<E, A2, B>((a2) {
      return run(f(a2));
    });
  }

  EitherArrow<E, A, Sub> then<Sub>(EitherArrow<E, B, Sub> other) {
    return EitherArrow.fromRun<E, A, Sub>((a) {
      return run(a).bind<Sub>(other.run);
    });
  }

  EitherArrow<E, A2, B> after<A2>(EitherArrow<E, A2, A> other) {
    return other.then<B>(this);
  }

  EitherArrow<E, A, (B, B2)> zip<B2>(EitherArrow<E, A, B2> other) {
    return EitherArrow.fromRun<E, A, (B, B2)>((a) {
      return run(a).zip<B2>(other.run(a));
    });
  }

  EitherArrow<E2, A, B> recover<E2>(EitherArrow<E2, E, B> other) {
    return EitherArrow.fromRun<E2, A, B>((a) {
      return run(a).rescue<E2>(other.run);
    });
  }

  EitherArrow<E, A, B> orElseArrow(EitherArrow<E, A, B> fallback) {
    return orElseFunc<E>(constfunc(fallback));
  }

  EitherArrow<E2, A, B> orElseFunc<E2>(Func<E, EitherArrow<E2, A, B>> f) {
    return EitherArrow.fromRun<E2, A, B>((a) {
      return run(a).match<Either<E2, B>>((e) => f(e).run(a), Either.right<E2, B>);
    });
  }

  static EitherArrow<E, A, IList<B>> zipAll<E, A, B>(IList<EitherArrow<E, A, B>> list) {
    return list.fold<EitherArrow<E, A, IList<B>>>(EitherArrow.fromRun<E, A, IList<B>>((_) => Either.right<E, IList<B>>(IList<B>.empty())), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  EitherArrow<E, (P, A), (P, B)> strong<P>() {
    return EitherArrow.fromRun<E, (P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  EitherArrow<E, Either<P, A>, Either<P, B>> choice<P>() {
    return EitherArrow.fromRun<E, Either<P, A>, Either<P, B>>((either) {
      return either.match<Either<E, Either<P, B>>>(
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
