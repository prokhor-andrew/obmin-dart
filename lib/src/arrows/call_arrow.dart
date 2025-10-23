// Copyright (c) 2024 Andrii Prokhorenko
// This file is b of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class CallArrow<E, A, B> {
  final Func<A, Call<E, B>> run;

  const CallArrow._(this.run);

  static CallArrow<E, A, B> fromRun<E, A, B>(Func<A, Call<E, B>> run) {
    return CallArrow._(run);
  }

  static CallArrow<E, A, B> fromFunc<E, A, B>(Func<A, B> f) {
    return CallArrow.fromRun<E, A, B>((a) {
      final b = f(a);
      return CallArrow.id<E, B>().run(b);
    });
  }

  static CallArrow<E, A, ()> unit<E, A>() {
    return CallArrow.fromRun<E, A, ()>(constfunc(Call.returned<E, ()>(())));
  }

  static CallArrow<E, A, A> id<E, A>() {
    return CallArrow.fromRun<E, A, A>(Call.returned<E, A>);
  }

  CallArrow<E, A, B2> rmap<B2>(Func<B, B2> f) {
    return CallArrow.fromRun<E, A, B2>((a) {
      return run(a).rmap<B2>(f);
    });
  }

  CallArrow<E2, A, B> lmap<E2>(Func<E, E2> f) {
    return CallArrow.fromRun<E2, A, B>((a) {
      return run(a).lmap<E2>(f);
    });
  }

  CallArrow<E2, A, B2> bimap<E2, B2>(Func<E, E2> lf, Func<B, B2> rf) {
    return lmap<E2>(lf).rmap<B2>(rf);
  }

  CallArrow<E, A2, B2> promap<A2, B2>(Func<A2, A> lf, Func<B, B2> rf) {
    return cmap<A2>(lf).rmap<B2>(rf);
  }

  CallArrow<E, A2, B> cmap<A2>(Func<A2, A> f) {
    return CallArrow.fromRun<E, A2, B>((a2) {
      return run(f(a2));
    });
  }

  CallArrow<E, A, Sub> then<Sub>(CallArrow<E, B, Sub> other) {
    return CallArrow.fromRun<E, A, Sub>((a) {
      return run(a).bind<Sub>(other.run);
    });
  }

  CallArrow<E, A2, B> after<A2>(CallArrow<E, A2, A> other) {
    return other.then<B>(this);
  }

  CallArrow<E, A, (B, B2)> zip<B2>(CallArrow<E, A, B2> other) {
    return CallArrow.fromRun<E, A, (B, B2)>((a) {
      return run(a).zip<B2>(other.run(a));
    });
  }

  CallArrow<E2, A, B> lthen<E2>(CallArrow<E2, E, B> other) {
    return CallArrow.fromRun<E2, A, B>((a) {
      return run(a).lbind<E2>(other.run);
    });
  }

  static CallArrow<E, A, IList<B>> zipAll<E, A, B>(IList<CallArrow<E, A, B>> list) {
    return list.fold<CallArrow<E, A, IList<B>>>(CallArrow.fromRun<E, A, IList<B>>((_) => Call.returned<E, IList<B>>(IList<B>.empty())), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  CallArrow<E, (P, A), (P, B)> strong<P>() {
    return CallArrow.fromRun<E, (P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  CallArrow<E, Either<P, A>, Either<P, B>> choice<P>() {
    return CallArrow.fromRun<E, Either<P, A>, Either<P, B>>((either) {
      return either.match<Call<E, Either<P, B>>>(
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
