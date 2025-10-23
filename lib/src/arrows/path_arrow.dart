// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class PathArrow<K, A, B> {
  final Func<A, Path<K, B>> run;

  const PathArrow._(this.run);

  static PathArrow<K, A, B> fromRun<K, A, B>(Func<A, Path<K, B>> run) => PathArrow._(run);

  static PathArrow<K, A, B> fromFunc<K, A, B>(Func<A, B> f) {
    return PathArrow.fromRun<K, A, B>((a) => Path.of<K, B>(f(a)));
  }

  PathArrow<K, A, B2> rmap<B2>(Func<B, B2> f) {
    return PathArrow.fromRun<K, A, B2>((tuple) {
      return run(tuple).rmap<B2>(f);
    });
  }

  PathArrow<K, A2, B> cmap<A2>(Func<A2, A> f) {
    return PathArrow.fromRun<K, A2, B>((tuple) {
      return run(f(tuple));
    });
  }

  PathArrow<K, A2, B2> promap<A2, B2>(Func<A2, A> lf, Func<B, B2> rf) {
    return cmap<A2>(lf).rmap<B2>(rf);
  }

  static PathArrow<K, A, A> id<K, A>() => PathArrow.fromRun(Path.of);

  PathArrow<K, A, Sub> then<Sub>(PathArrow<K, B, Sub> other) {
    return PathArrow.fromRun<K, A, Sub>((a) {
      return run(a).bind(other.run);
    });
  }

  PathArrow<K, A2, B> after<A2>(PathArrow<K, A2, A> other) {
    return other.then<B>(this);
  }

  static PathArrow<K, A, ()> unit<K, A>() {
    return PathArrow.fromRun<K, A, ()>(constfunc(Path.unit<K>()));
  }

  PathArrow<K, A, (B, B2)> zip<B2>(PathArrow<K, A, B2> other) {
    return PathArrow.fromRun<K, A, (B, B2)>((a) {
      return run(a).zip(other.run(a));
    });
  }

  static PathArrow<K, A, IList<B>> zipAll<K, A, B>(IList<PathArrow<K, A, B>> list) {
    return list.fold<PathArrow<K, A, IList<B>>>(PathArrow.fromRun<K, A, IList<B>>((_) => Path.empty<K, IList<B>>()), (current, element) {
      final arrow = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(arrow).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  static PathArrow<K, A, Never> zero<K, A>() {
    return PathArrow.fromRun<K, A, Never>(constfunc(Path.zero<K>()));
  }

  PathArrow<K, A, Either<B, B2>> altMerge<B2>(PathArrow<K, A, B2> other) {
    return PathArrow.fromRun<K, A, Either<B, B2>>((a) {
      final path1 = run(a);
      final path2 = other.run(a);

      return path1.altMerge(path2);
    });
  }

  PathArrow<K, A, Either<B, B2>> altLeftBiased<B2>(PathArrow<K, A, B2> other) {
    return PathArrow.fromRun<K, A, Either<B, B2>>((a) {
      final path1 = run(a);
      final path2 = other.run(a);

      return path1.altLeftBiased(path2);
    });
  }

  static PathArrow<K, A, (int, B)> altAllTaggedLeftBiased<K, A, B>(IList<PathArrow<K, A, B>> list) {
    return list.indexed.fold<PathArrow<K, A, (int, B)>>(PathArrow.zero<K, A>(), (current, element) {
      final (index, arrow) = element;
      final arr = arrow.rmap<(int, B)>((value) => (index, value));
      return current.altLeftBiased<(int, B)>(arr).rmap<(int, B)>((either) {
        return either.value();
      });
    });
  }

  static PathArrow<K, A, B> altAllLeftBiased<K, A, B>(IList<PathArrow<K, A, B>> list) {
    return altAllTaggedLeftBiased(list).rmap((tuple) => tuple.$2);
  }

  static PathArrow<K, A, (int, B)> altAllTaggedMerge<K, A, B>(IList<PathArrow<K, A, B>> list) {
    return list.indexed.fold<PathArrow<K, A, (int, B)>>(PathArrow.zero<K, A>(), (current, element) {
      final (index, arrow) = element;
      final arr = arrow.rmap<(int, B)>((value) => (index, value));
      return current.altMerge<(int, B)>(arr).rmap<(int, B)>((either) {
        return either.value();
      });
    });
  }

  static PathArrow<K, A, B> altAllMerge<K, A, B>(IList<PathArrow<K, A, B>> list) {
    return altAllTaggedMerge(list).rmap((tuple) => tuple.$2);
  }

  PathArrow<K, (P, A), (P, B)> strong<P>() {
    return PathArrow.fromRun<K, (P, A), (P, B)>((tuple) {
      final (p, a) = tuple;
      final functor = run(a);
      return functor.rmap<(P, B)>((b) => (p, b));
    });
  }

  PathArrow<K, Either<P, A>, Either<P, B>> choice<P>() {
    return PathArrow.fromRun<K, Either<P, A>, Either<P, B>>((either) {
      return either.match<Path<K, Either<P, B>>>(
        (p) {
          return PathArrow.id<K, Either<P, B>>().run(Either.left<P, B>(p));
        },
        (a) {
          final functor = run(a);
          return functor.rmap<Either<P, B>>((b) => Either.right<P, B>(b));
        },
      );
    });
  }
}
