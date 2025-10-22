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

  static PathArrow<String, Either<E, B>, B> eitherRight<E, B>() {
    return PathArrow.fromRun<String, Either<E, B>, B>((either) {
      return either.match<Path<String, B>>(constfunc(Path.empty<String, B>()), (value) {
        return Path.fromKeyValue<String, B>("right", value);
      });
    });
  }

  static PathArrow<String, Either<B, E>, B> eitherLeft<E, B>() {
    return PathArrow.fromRun<String, Either<B, E>, B>((either) {
      return either.match<Path<String, B>>((value) {
        return Path.fromKeyValue<String, B>("left", value);
      }, constfunc(Path.empty<String, B>()));
    });
  }

  static PathArrow<String, Call<E, B>, B> callReturned<E, B>() {
    return PathArrow.fromRun<String, Call<E, B>, B>((call) {
      return call.match<Path<String, B>>(constfunc(Path.empty<String, B>()), (value) {
        return Path.fromKeyValue("returned", value);
      });
    });
  }

  static PathArrow<String, Call<B, E>, B> callLaunched<E, B>() {
    return PathArrow.fromRun<String, Call<B, E>, B>((call) {
      return call.match<Path<String, B>>((value) {
        return Path.fromKeyValue("launched", value);
      }, constfunc(Path.empty<String, B>()));
    });
  }

  static PathArrow<String, Result<E, B>, B> resultSuccess<E, B>() {
    return PathArrow.fromRun<String, Result<E, B>, B>((result) {
      return result.match<Path<String, B>>(constfunc(Path.empty<String, B>()), (value) {
        return Path.fromKeyValue("success", value);
      });
    });
  }

  static PathArrow<String, Result<B, E>, B> resultFailure<E, B>() {
    return PathArrow.fromRun<String, Result<B, E>, B>((result) {
      return result.match<Path<String, B>>((value) {
        return Path.fromKeyValue("failure", value);
      }, constfunc(Path.empty<String, B>()));
    });
  }

  static PathArrow<String, Writer<E, B>, B> writerValue<E, B>() {
    return PathArrow.fromRun<String, Writer<E, B>, B>((writer) {
      return Path.fromKeyValue("value", writer.value());
    });
  }

  static PathArrow<String, Writer<B, E>, IList<B>> writerList<E, B>() {
    return PathArrow.fromRun<String, Writer<B, E>, IList<B>>((writer) {
      return Path.fromKeyValue("list", writer.list());
    });
  }

  static PathArrow<String, Validator<E, B>, B> validatorValue<E, B>() {
    return PathArrow.fromRun<String, Validator<E, B>, B>((validator) {
      return validator.match(constfunc(Path.empty<String, B>()), (value) {
        return Path.fromKeyValue("value", value);
      });
    });
  }

  static PathArrow<String, Validator<B, E>, IList<B>> validatorErrors<E, B>() {
    return PathArrow.fromRun<String, Validator<B, E>, IList<B>>((validator) {
      return validator.match<Path<String, IList<B>>>((errors) {
        return Path.fromKeyValue("errors", errors);
      }, constfunc(Path.empty<String, IList<B>>()));
    });
  }

  static PathArrow<String, Logger<B>, B> logger<B>() {
    return PathArrow.fromRun<String, Logger<B>, B>((logger) {
      return Path.fromKeyValue("value", logger.value());
    });
  }

  static PathArrow<String, Option<B>, B> option<B>() {
    return PathArrow.fromRun<String, Option<B>, B>((option) {
      return option.match(Path.empty<String, B>, (value) {
        return Path.fromKeyValue("some", value);
      });
    });
  }

  static PathArrow<String, IList<B>, B> list<B>() {
    return PathArrow.fromRun<String, IList<B>, B>((list) {
      IMap<IList<String>, B> result = IMap<IList<String>, B>.empty();

      list.indexed.forEach((tuple) {
        final (index, value) = tuple;
        result = result.add(["$index"].lock, value);
      });

      return Path.fromMap(result);
    });
  }

  static PathArrow<String, IMap<Key, B>, B> dict<Key, B>() {
    return PathArrow.fromRun<String, IMap<Key, B>, B>((map) {
      return Path.fromMap(map.map<IList<String>, B>((key, value) => MapEntry([key.toString()].lock, value)));
    });
  }

  static PathArrow<String, (E, B), B> tupleRight<E, B>() {
    return PathArrow.fromRun<String, (E, B), B>((tuple) {
      return Path.fromKeyValue("right", tuple.$2);
    });
  }

  static PathArrow<String, (B, E), B> tupleLeft<E, B>() {
    return PathArrow.fromRun<String, (B, E), B>((tuple) {
      return Path.fromKeyValue("left", tuple.$1);
    });
  }

  static PathArrow<String, These<E, B>, B> theseRight<E, B>() {
    return PathArrow.fromRun<String, These<E, B>, B>((these) {
      return these.match<Path<String, B>>(
        (left) => Path.empty<String, B>(),
        (right) {
          return Path.fromKeyValue("right", right);
        },
        (_, right) {
          return Path.fromKeyValue("right", right);
        },
      );
    });
  }

  static PathArrow<String, These<B, E>, B> theseLeft<E, B>() {
    return PathArrow.fromRun<String, These<B, E>, B>((these) {
      return these.match<Path<String, B>>(
        (left) {
          return Path.fromKeyValue("left", left);
        },
        (right) => Path.empty<String, B>(),
        (left, _) {
          return Path.fromKeyValue("left", left);
        },
      );
    });
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
