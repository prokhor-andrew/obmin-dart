// Copyright (c) 2024 Andrii Prokhorenko
// This file is b of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class CrossJoinListArrow<A, B> {
  final Func<A, CrossJoinList<B>> run;

  const CrossJoinListArrow._(this.run);

  static CrossJoinListArrow<A, B> fromRun<A, B>(Func<A, CrossJoinList<B>> run) {
    return CrossJoinListArrow._(run);
  }

  static CrossJoinListArrow<A, B> fromFunc<A, B>(Func<A, B> f) {
    return fromRun<A, B>((a) {
      final b = f(a);
      return CrossJoinListArrow.id<B>().run(b);
    });
  }

  static CrossJoinListArrow<A, ()> unit<A>() {
    return CrossJoinListArrow.fromRun<A, ()>(constfunc(CrossJoinList.unit()));
  }

  static CrossJoinListArrow<A, Never> zero<A>() {
    return CrossJoinListArrow.fromRun<A, Never>(constfunc(CrossJoinList.zero()));
  }

  static CrossJoinListArrow<A, A> id<A>() {
    return CrossJoinListArrow.fromRun<A, A>(CrossJoinList.of);
  }

  CrossJoinListArrow<A, Part2> rmap<Part2>(Func<B, Part2> f) {
    return CrossJoinListArrow.fromRun<A, Part2>((a) {
      return run(a).rmap<Part2>(f);
    });
  }

  CrossJoinListArrow<Whole2, B> cmap<Whole2>(Func<Whole2, A> f) {
    return CrossJoinListArrow.fromRun<Whole2, B>((whole2) {
      return run(f(whole2));
    });
  }

  CrossJoinListArrow<Whole2, Part2> promap<Whole2, Part2>(Func<Whole2, A> lf, Func<B, Part2> rf) {
    return cmap<Whole2>(lf).rmap<Part2>(rf);
  }

  CrossJoinListArrow<A, Sub> then<Sub>(CrossJoinListArrow<B, Sub> other) {
    return CrossJoinListArrow.fromRun<A, Sub>((a) {
      return run(a).bind<Sub>(other.run);
    });
  }

  CrossJoinListArrow<Whole2, B> after<Whole2>(CrossJoinListArrow<Whole2, A> other) {
    return other.then<B>(this);
  }

  CrossJoinListArrow<A, (B, Part2)> zip<Part2>(CrossJoinListArrow<A, Part2> other) {
    return CrossJoinListArrow.fromRun<A, (B, Part2)>((a) {
      return run(a).zip<Part2>(other.run(a));
    });
  }

  CrossJoinListArrow<A, Either<B, Part2>> altConcat<Part2>(CrossJoinListArrow<A, Part2> other) {
    return CrossJoinListArrow.fromRun<A, Either<B, Part2>>((a) {
      final b = run(a);
      final part2 = other.run(a);
      return b.altConcat<Part2>(part2);
    });
  }

  CrossJoinListArrow<A, Either<B, Part2>> altLeftBiased<Part2>(CrossJoinListArrow<A, Part2> other) {
    return CrossJoinListArrow.fromRun<A, Either<B, Part2>>((a) {
      final b = run(a);
      final part2 = other.run(a);
      return b.altLeftBiased<Part2>(part2);
    });
  }

  static CrossJoinListArrow<A, IList<B>> zipAll<A, B>(IList<CrossJoinListArrow<A, B>> list) {
    return list.fold<CrossJoinListArrow<A, IList<B>>>(CrossJoinListArrow.fromRun<A, IList<B>>((_) => CrossJoinList.of<IList<B>>(IList<B>.empty())), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  static CrossJoinListArrow<A, (int, B)> altAllTaggedLeftBiased<A, B>(IList<CrossJoinListArrow<A, B>> list) {
    return list.indexed.fold<CrossJoinListArrow<A, (int, B)>>(CrossJoinListArrow.fromRun<A, (int, B)>((_) => CrossJoinList.empty<(int, B)>()), (current, element) {
      final (index, option) = element;
      final arrow = option.rmap<(int, B)>((value) => (index, value));
      return current.altLeftBiased<(int, B)>(arrow).rmap<(int, B)>((either) {
        return either.value();
      });
    });
  }

  static CrossJoinListArrow<A, B> altAllLeftBiased<A, B>(IList<CrossJoinListArrow<A, B>> list) {
    return altAllTaggedLeftBiased(list).rmap((tuple) => tuple.$2);
  }

  static CrossJoinListArrow<A, (int, B)> altAllTaggedConcat<A, B>(IList<CrossJoinListArrow<A, B>> list) {
    return list.indexed.fold(CrossJoinListArrow.fromRun<A, (int, B)>((_) => CrossJoinList.empty<(int, B)>()), (current, element) {
      final (index, option) = element;
      final arrow = option.rmap<(int, B)>((value) => (index, value));
      return current.altConcat<(int, B)>(arrow).rmap<(int, B)>((either) {
        return either.value();
      });
    });
  }

  static CrossJoinListArrow<A, B> altAllConcat<A, B>(IList<CrossJoinListArrow<A, B>> list) {
    return altAllTaggedConcat(list).rmap((tuple) => tuple.$2);
  }

  CrossJoinListArrow<(P, A), (P, B)> strong<P>() {
    return CrossJoinListArrow.fromRun<(P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  CrossJoinListArrow<Either<P, A>, Either<P, B>> choice<P>() {
    return CrossJoinListArrow.fromRun<Either<P, A>, Either<P, B>>((either) {
      return either.match<CrossJoinList<Either<P, B>>>(
        (p) {
          return CrossJoinListArrow.id<Either<P, B>>().run(Either.left<P, B>(p));
        },
        (a) {
          final functor = run(a);
          return functor.rmap<Either<P, B>>((b) => Either.right<P, B>(b));
        },
      );
    });
  }
}
