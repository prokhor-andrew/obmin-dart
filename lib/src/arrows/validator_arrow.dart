// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class ValidatorArrow<E, A, B> {
  final Func<A, Validator<E, B>> run;

  const ValidatorArrow._(this.run);

  static ValidatorArrow<E, A, B> fromRun<E, A, B>(Func<A, Validator<E, B>> run) {
    return ValidatorArrow._(run);
  }

  static ValidatorArrow<E, A, B> fromFunc<E, A, B>(Func<A, B> f) {
    return ValidatorArrow.fromRun<E, A, B>((a) {
      final b = f(a);
      return ValidatorArrow.id<E, B>().run(b);
    });
  }

  static ValidatorArrow<E, A, ()> unit<E, A>() {
    return ValidatorArrow.fromRun<E, A, ()>(constfunc<A, Validator<E, ()>>(Validator.of<E, ()>(())));
  }

  static ValidatorArrow<E, A, Never> zero<E, A>() {
    return ValidatorArrow.fromRun<E, A, Never>(constfunc<A, Validator<E, Never>>(Validator.errors<E, Never>(IList<E>.empty())));
  }

  ValidatorArrow<E, A, B2> rmap<B2>(Func<B, B2> f) {
    return ValidatorArrow.fromRun<E, A, B2>((a) {
      return run(a).rmap<B2>(f);
    });
  }

  ValidatorArrow<E2, A, B> lmap<E2>(Func<E, E2> f) {
    return ValidatorArrow.fromRun<E2, A, B>((a) {
      return run(a).lmap<E2>(f);
    });
  }

  ValidatorArrow<E, A2, B> cmap<A2>(Func<A2, A> f) {
    return ValidatorArrow.fromRun<E, A2, B>((a2) {
      return run(f(a2));
    });
  }

  ValidatorArrow<E2, A, B2> bimap<E2, B2>(Func<E, E2> lf, Func<B, B2> rf) {
    return lmap<E2>(lf).rmap<B2>(rf);
  }

  ValidatorArrow<E, A2, B2> promap<A2, B2>(Func<A2, A> lf, Func<B, B2> rf) {
    return cmap<A2>(lf).rmap<B2>(rf);
  }

  static ValidatorArrow<E, A, A> id<E, A>() {
    return ValidatorArrow.fromRun<E, A, A>(Validator.of<E, A>);
  }

  ValidatorArrow<E, A, (B, B2)> zip<B2>(ValidatorArrow<E, A, B2> other) {
    return ValidatorArrow.fromRun<E, A, (B, B2)>((a) {
      return run(a).zip<B2>(other.run(a));
    });
  }

  ValidatorArrow<E, A, Either<B, B2>> altLeftBiased<B2>(ValidatorArrow<E, A, B2> other) {
    return ValidatorArrow.fromRun<E, A, Either<B, B2>>((a) {
      final b = run(a);
      final b2 = other.run(a);
      return b.altLeftBiased<B2>(b2);
    });
  }

  ValidatorArrow<E, A, Either<B, B2>> altConcat<B2>(ValidatorArrow<E, A, B2> other) {
    return ValidatorArrow.fromRun<E, A, Either<B, B2>>((a) {
      final b = run(a);
      final b2 = other.run(a);
      return b.altConcat<B2>(b2);
    });
  }

  static ValidatorArrow<E, A, IList<B>> zipAll<E, A, B>(IList<ValidatorArrow<E, A, B>> list) {
    return list.fold<ValidatorArrow<E, A, IList<B>>>(ValidatorArrow.fromRun<E, A, IList<B>>((_) => Validator.of<E, IList<B>>(IList<B>.empty())), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  static ValidatorArrow<E, A, (int, B)> altAllConcatTagged<E, A, B>(IList<ValidatorArrow<E, A, B>> list) {
    return list.indexed.fold<ValidatorArrow<E, A, (int, B)>>(ValidatorArrow.zero<E, A>(), (current, element) {
      final (index, option) = element;
      final indexedOption = option.rmap<(int, B)>((value) => (index, value));
      return current.altConcat<(int, B)>(indexedOption).rmap<(int, B)>((either) {
        return either.value();
      });
    });
  }

  static ValidatorArrow<E, A, B> altAllConcat<E, A, B>(IList<ValidatorArrow<E, A, B>> list) {
    return altAllConcatTagged(list).rmap((tuple) => tuple.$2);
  }

  static ValidatorArrow<E, A, (int, B)> altAllLeftBiasedTagged<E, A, B>(IList<ValidatorArrow<E, A, B>> list) {
    return list.indexed.fold<ValidatorArrow<E, A, (int, B)>>(ValidatorArrow.zero<E, A>(), (current, element) {
      final (index, option) = element;
      final indexedOption = option.rmap<(int, B)>((value) => (index, value));
      return current.altLeftBiased<(int, B)>(indexedOption).rmap<(int, B)>((either) {
        return either.value();
      });
    });
  }

  static ValidatorArrow<E, A, B> altAllLeftBiased<E, A, B>(IList<ValidatorArrow<E, A, B>> list) {
    return altAllLeftBiasedTagged(list).rmap((tuple) => tuple.$2);
  }

  ValidatorArrow<E, (P, A), (P, B)> strong<P>() {
    return ValidatorArrow.fromRun<E, (P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  ValidatorArrow<E, Either<P, A>, Either<P, B>> choice<P>() {
    return ValidatorArrow.fromRun<E, Either<P, A>, Either<P, B>>((either) {
      return either.match<Validator<E, Either<P, B>>>(
        (p) {
          return ValidatorArrow.id<E, Either<P, B>>().run(Either.left<P, B>(p));
        },
        (a) {
          final functor = run(a);
          return functor.rmap<Either<P, B>>((b) => Either.right<P, B>(b));
        },
      );
    });
  }
}
