// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin/obmin.dart';

final class PolyOptic<Whole, TWhole, Part, TPart> {
  final Func<Func<Part, TPart>, Func<Whole, TWhole>> run;

  Func<Whole, TWhole> set(TPart value) => run(constfunc(value));

  const PolyOptic._(this.run);

  static PolyOptic<Whole, TWhole, Part, TPart> fromRun<Whole, TWhole, Part, TPart>(Func<Func<Part, TPart>, Func<Whole, TWhole>> run) {
    return PolyOptic._(run);
  }

  static PolyOptic<T, T, T, T> id<T>() {
    return PolyOptic.fromRun<T, T, T, T>(idfunc);
  }

  static PolyOptic<Whole, TWhole, Part, TPart> adapter<Whole, TWhole, Part, TPart>(Func<Whole, Part> focus, Func<TPart, TWhole> reconstruct) {
    return PolyOptic.fromRun<Whole, TWhole, Part, TPart>((update) {
      return (whole) {
        final part = focus(whole);
        final updated = update(part);
        return reconstruct(updated);
      };
    });
  }

  static PolyOptic<Whole, TWhole, Part, TPart> lens<Whole, TWhole, Part, TPart>(Func<Whole, Part> focus, Func<Whole, Func<TPart, TWhole>> reconstruct) {
    return PolyOptic.fromRun<Whole, TWhole, Part, TPart>((update) {
      return (whole) {
        final part = focus(whole);
        final updated = update(part);
        return reconstruct(whole)(updated);
      };
    });
  }

  static PolyOptic<Whole, TWhole, Part, TPart> prism<Whole, TWhole, Part, TPart>(Func<Whole, Either<TWhole, Part>> focus, Func<TPart, TWhole> reconstruct) {
    return PolyOptic.fromRun<Whole, TWhole, Part, TPart>((update) {
      return (whole) {
        final partOrNewWhole = focus(whole);
        final updatedOrNewWhole = partOrNewWhole.rmap<TPart>(update);
        return updatedOrNewWhole.rmap<TWhole>(reconstruct).value();
      };
    });
  }

  PolyOptic<Whole, TWhole, Sub, TSub> then<Sub, TSub>(PolyOptic<Part, TPart, Sub, TSub> other) {
    return PolyOptic.fromRun<Whole, TWhole, Sub, TSub>((update) {
      return (whole) {
        return run((part) {
          return other.run(update)(part);
        })(whole);
      };
    });
  }

  PolyOptic<Whole2, TWhole2, Part, TPart> after<Whole2, TWhole2>(PolyOptic<Whole2, TWhole2, Whole, TWhole> other) {
    return other.then<Part, TPart>(this);
  }
}
