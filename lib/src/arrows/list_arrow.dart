// Copyright (c) 2024 Andrii Prokhorenko
// This file is b of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class ListArrow<A, B> {
  final Func<A, IList<B>> run;

  const ListArrow._(this.run);

  static ListArrow<A, B> fromRun<A, B>(Func<A, IList<B>> run) {
    return ListArrow._(run);
  }

  static ListArrow<A, B> fromFunc<A, B>(Func<A, B> f) {
    return fromRun<A, B>((a) {
      final b = f(a);
      return ListArrow.id<B>().run(b);
    });
  }

  static ListArrow<A, ()> unit<A>() {
    return ListArrow.fromRun<A, ()>(constfunc([()].lock));
  }

  static ListArrow<A, Never> zero<A>() {
    return ListArrow.fromRun<A, Never>(constfunc(const IList<Never>.empty()));
  }

  static ListArrow<A, A> id<A>() {
    return ListArrow.fromRun<A, A>((value) => [value].lock);
  }

  ListArrow<A, Part2> rmap<Part2>(Func<B, Part2> f) {
    return ListArrow.fromRun<A, Part2>((a) {
      return run(a).rmap<Part2>(f);
    });
  }

  ListArrow<Whole2, B> cmap<Whole2>(Func<Whole2, A> f) {
    return ListArrow.fromRun<Whole2, B>((whole2) {
      return run(f(whole2));
    });
  }

  ListArrow<Whole2, Part2> promap<Whole2, Part2>(Func<Whole2, A> lf, Func<B, Part2> rf) {
    return cmap<Whole2>(lf).rmap<Part2>(rf);
  }

  ListArrow<A, Sub> then<Sub>(ListArrow<B, Sub> other) {
    return ListArrow.fromRun<A, Sub>((a) {
      return run(a).bind<Sub>(other.run);
    });
  }

  ListArrow<Whole2, B> after<Whole2>(ListArrow<Whole2, A> other) {
    return other.then<B>(this);
  }

  ListArrow<A, (B, Part2)> zip<Part2>(ListArrow<A, Part2> other) {
    return ListArrow.fromRun<A, (B, Part2)>((a) {
      return run(a).rzip<Part2>(other.run(a));
    });
  }

  ListArrow<A, Either<B, Part2>> altConcat<Part2>(ListArrow<A, Part2> other) {
    return ListArrow.fromRun<A, Either<B, Part2>>((a) {
      final b = run(a);
      final part2 = other.run(a);
      return b.altConcat<Part2>(part2);
    });
  }

  ListArrow<A, Either<B, Part2>> altLeftBiased<Part2>(ListArrow<A, Part2> other) {
    return ListArrow.fromRun<A, Either<B, Part2>>((a) {
      final b = run(a);
      final part2 = other.run(a);
      return b.altLeftBiased<Part2>(part2);
    });
  }

  static ListArrow<A, IList<B>> zipAll<A, B>(IList<ListArrow<A, B>> list) {
    return list.fold<ListArrow<A, IList<B>>>(ListArrow.fromRun<A, IList<B>>((_) => [IList<B>.empty()].lock), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  static ListArrow<A, (int, B)> altAllLeftBiasedTagged<A, B>(IList<ListArrow<A, B>> list) {
    return list.indexed.fold<ListArrow<A, (int, B)>>(ListArrow.fromRun<A, (int, B)>((_) => <(int, B)>[].lock), (current, element) {
      final (index, option) = element;
      final arrow = option.rmap<(int, B)>((value) => (index, value));
      return current.altLeftBiased<(int, B)>(arrow).rmap<(int, B)>((either) {
        return either.value();
      });
    });
  }

  static ListArrow<A, B> altAllLeftBiased<A, B>(IList<ListArrow<A, B>> list) {
    return altAllLeftBiasedTagged(list).rmap((tuple) => tuple.$2);
  }

  static ListArrow<A, (int, B)> altAllConcatTagged<A, B>(IList<ListArrow<A, B>> list) {
    return list.indexed.fold(ListArrow.fromRun<A, (int, B)>((_) => <(int, B)>[].lock), (current, element) {
      final (index, option) = element;
      final arrow = option.rmap<(int, B)>((value) => (index, value));
      return current.altConcat<(int, B)>(arrow).rmap<(int, B)>((either) {
        return either.value();
      });
    });
  }

  static ListArrow<A, B> altAllConcat<A, B>(IList<ListArrow<A, B>> list) {
    return altAllConcatTagged(list).rmap((tuple) => tuple.$2);
  }

  ListArrow<(P, A), (P, B)> strong<P>() {
    return ListArrow.fromRun<(P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  ListArrow<Either<P, A>, Either<P, B>> choice<P>() {
    return ListArrow.fromRun<Either<P, A>, Either<P, B>>((either) {
      return either.match<IList<Either<P, B>>>(
        (p) {
          return ListArrow.id<Either<P, B>>().run(Either.left<P, B>(p));
        },
        (a) {
          final functor = run(a);
          return functor.rmap<Either<P, B>>((b) => Either.right<P, B>(b));
        },
      );
    });
  }
}
