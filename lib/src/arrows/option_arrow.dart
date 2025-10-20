// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class OptionArrow<A, B> {
  final Func<A, Option<B>> run;

  const OptionArrow._(this.run);

  static OptionArrow<A, B> fromRun<A, B>(Func<A, Option<B>> run) {
    return OptionArrow._(run);
  }

  static OptionArrow<A, B> fromFunc<A, B>(Func<A, B> f) {
    return fromRun<A, B>((a) {
      final b = f(a);
      return OptionArrow.id<B>().run(b);
    });
  }

  static OptionArrow<Either<E, B>, B> eitherRight<E, B>() {
    return OptionArrow.fromRun<Either<E, B>, B>((either) {
      return either.match<Option<B>>(constfunc(Option.none()), Option.some);
    });
  }

  static OptionArrow<Either<B, E>, B> eitherLeft<E, B>() {
    return OptionArrow.fromRun<Either<B, E>, B>((either) {
      return either.match<Option<B>>(Option.some, constfunc(Option.none()));
    });
  }

  static OptionArrow<Call<E, B>, B> callReturned<E, B>() {
    return OptionArrow.fromRun<Call<E, B>, B>((call) {
      return call.match<Option<B>>(constfunc(Option.none()), Option.some);
    });
  }

  static OptionArrow<Call<B, E>, B> callLaunched<E, B>() {
    return OptionArrow.fromRun<Call<B, E>, B>((call) {
      return call.match<Option<B>>(Option.some, constfunc(Option.none()));
    });
  }

  static OptionArrow<Result<E, B>, B> resultSuccess<E, B>() {
    return OptionArrow.fromRun<Result<E, B>, B>((result) {
      return result.match<Option<B>>(constfunc(Option.none()), Option.some);
    });
  }

  static OptionArrow<Result<B, E>, B> resultFailure<E, B>() {
    return OptionArrow.fromRun<Result<B, E>, B>((result) {
      return result.match<Option<B>>(Option.some, constfunc(Option.none()));
    });
  }

  static OptionArrow<Writer<E, B>, B> writerValue<E, B>() {
    return OptionArrow.fromRun<Writer<E, B>, B>((writer) {
      return Option.some(writer.value());
    });
  }

  static OptionArrow<Writer<B, E>, IList<B>> writerList<E, B>() {
    return OptionArrow.fromRun<Writer<B, E>, IList<B>>((writer) {
      return Option.some(writer.list());
    });
  }

  static OptionArrow<Validator<E, B>, B> validatorValue<E, B>() {
    return OptionArrow.fromRun<Validator<E, B>, B>((validator) {
      return validator.match(constfunc(Option.none()), Option.some);
    });
  }

  static OptionArrow<Validator<B, E>, IList<B>> validatorErrors<E, B>() {
    return OptionArrow.fromRun<Validator<B, E>, IList<B>>((validator) {
      return validator.match(Option.some, constfunc(Option.none()));
    });
  }

  static OptionArrow<Logger<B>, B> logger<B>() {
    return OptionArrow.fromRun<Logger<B>, B>((logger) {
      return Option.some(logger.value());
    });
  }

  static OptionArrow<Option<B>, B> option<B>() {
    return OptionArrow.fromRun<Option<B>, B>(idfunc);
  }

  static OptionArrow<(E, B), B> tupleRight<E, B>() {
    return OptionArrow.fromRun<(E, B), B>((tuple) {
      return Option.some(tuple.$2);
    });
  }

  static OptionArrow<(B, E), B> tupleLeft<E, B>() {
    return OptionArrow.fromRun<(B, E), B>((tuple) {
      return Option.some(tuple.$1);
    });
  }

  static OptionArrow<These<E, B>, B> theseRight<E, B>() {
    return OptionArrow.fromRun<These<E, B>, B>((these) {
      return these.match<Option<B>>(constfunc(Option.none()), Option.some, (_, right) {
        return Option.some(right);
      });
    });
  }

  static OptionArrow<These<B, E>, B> theseLeft<E, B>() {
    return OptionArrow.fromRun<These<B, E>, B>((these) {
      return these.match<Option<B>>(Option.some, constfunc(Option.none()), (left, _) {
        return Option.some(left);
      });
    });
  }

  static OptionArrow<A, A> id<A>() {
    return OptionArrow.fromRun<A, A>(Option.some);
  }

  static OptionArrow<A, ()> unit<A>() {
    return OptionArrow.fromRun<A, ()>(constfunc<A, Option<()>>(Option.some(())));
  }

  static OptionArrow<A, Never> zero<A>() {
    return OptionArrow.fromRun<A, Never>(constfunc<A, Option<Never>>(Option.none()));
  }

  OptionArrow<A, B2> rmap<B2>(Func<B, B2> f) {
    return OptionArrow.fromRun<A, B2>((a) {
      return run(a).rmap<B2>(f);
    });
  }

  OptionArrow<A2, B> cmap<A2>(Func<A2, A> f) {
    return OptionArrow.fromRun<A2, B>((a2) {
      return run(f(a2));
    });
  }

  OptionArrow<A2, B2> promap<A2, B2>(Func<A2, A> lf, Func<B, B2> rf) {
    return cmap<A2>(lf).rmap<B2>(rf);
  }

  OptionArrow<A, Sub> then<Sub>(OptionArrow<B, Sub> other) {
    return OptionArrow.fromRun<A, Sub>((a) {
      return run(a).bind<Sub>(other.run);
    });
  }

  OptionArrow<A2, B> after<A2>(OptionArrow<A2, A> other) {
    return other.then<B>(this);
  }

  OptionArrow<A, (B, B2)> zip<B2>(OptionArrow<A, B2> other) {
    return OptionArrow.fromRun<A, (B, B2)>((a) {
      return run(a).zip<B2>(other.run(a));
    });
  }

  OptionArrow<A, Either<B, B2>> alt<B2>(OptionArrow<A, B2> other) {
    return OptionArrow.fromRun<A, Either<B, B2>>((a) {
      final b = run(a);
      final b2 = other.run(a);
      return b.alt<B2>(b2);
    });
  }

  static OptionArrow<A, IList<B>> zipAll<A, B>(IList<OptionArrow<A, B>> list) {
    return list.fold<OptionArrow<A, IList<B>>>(OptionArrow.fromRun<A, IList<B>>((_) => Option.some<IList<B>>(IList<B>.empty())), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  static OptionArrow<A, (int, B)> altAllTagged<A, B>(IList<OptionArrow<A, B>> list) {
    return list.indexed.fold<OptionArrow<A, (int, B)>>(OptionArrow.fromRun<A, (int, B)>((_) => Option.none<(int, B)>()), (current, element) {
      final (index, option) = element;
      final indexedOption = option.rmap<(int, B)>((value) => (index, value));
      return current.alt(indexedOption).rmap<(int, B)>((either) {
        return either.value();
      });
    });
  }

  static OptionArrow<A, B> altAll<A, B>(IList<OptionArrow<A, B>> list) {
    return altAllTagged(list).rmap((tuple) => tuple.$2);
  }

  ListArrow<A, B> asListArrow() {
    return ListArrow.fromRun<A, B>((a) {
      return run(a).match<IList<B>>(IList<B>.empty, (value) => [value].lock);
    });
  }

  EitherArrow<(), A, B> asEitherArrow() {
    return EitherArrow.fromRun<(), A, B>((a) {
      return run(a).match<Either<(), B>>(() => Either.left<(), B>(()), Either.right<(), B>);
    });
  }

  OptionArrow<(P, A), (P, B)> strong<P>() {
    return OptionArrow.fromRun<(P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  OptionArrow<Either<P, A>, Either<P, B>> choice<P>() {
    return OptionArrow.fromRun<Either<P, A>, Either<P, B>>((either) {
      return either.match<Option<Either<P, B>>>(
        (p) {
          return OptionArrow.id<Either<P, B>>().run(Either.left<P, B>(p));
        },
        (a) {
          final functor = run(a);
          return functor.rmap<Either<P, B>>((b) => Either.right<P, B>(b));
        },
      );
    });
  }
}
