// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
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

  static PolyOptic<Option<Part>, Option<TPart>, Part, TPart> option<Part, TPart>() {
    return PolyOptic.fromRun<Option<Part>, Option<TPart>, Part, TPart>((update) {
      return (functor) {
        return functor.rmap<TPart>(update);
      };
    });
  }

  static PolyOptic<Writer<E, Part>, Writer<E, TPart>, Part, TPart> writerValue<E, Part, TPart>() {
    return PolyOptic.fromRun<Writer<E, Part>, Writer<E, TPart>, Part, TPart>((update) {
      return (functor) {
        return functor.rmap<TPart>(update);
      };
    });
  }

  static PolyOptic<Writer<Part, E>, Writer<TPart, E>, IList<Part>, IList<TPart>> writerList<E, Part, TPart>() {
    return PolyOptic.fromRun<Writer<Part, E>, Writer<TPart, E>, IList<Part>, IList<TPart>>((update) {
      return (writer) {
        return Writer(update(writer.list()), writer.value());
      };
    });
  }

  static PolyOptic<Either<E, Part>, Either<E, TPart>, Part, TPart> eitherRight<E, Part, TPart>() {
    return PolyOptic.fromRun<Either<E, Part>, Either<E, TPart>, Part, TPart>((update) {
      return (functor) {
        return functor.rmap<TPart>(update);
      };
    });
  }

  static PolyOptic<Either<Part, E>, Either<TPart, E>, Part, TPart> eitherLeft<E, Part, TPart>() {
    return PolyOptic.fromRun<Either<Part, E>, Either<TPart, E>, Part, TPart>((update) {
      return (functor) {
        return functor.lmap<TPart>(update);
      };
    });
  }

  static PolyOptic<Call<E, Part>, Call<E, TPart>, Part, TPart> callReturned<E, Part, TPart>() {
    return PolyOptic.fromRun<Call<E, Part>, Call<E, TPart>, Part, TPart>((update) {
      return (functor) {
        return functor.rmap<TPart>(update);
      };
    });
  }

  static PolyOptic<Call<Part, E>, Call<TPart, E>, Part, TPart> callLaunched<E, Part, TPart>() {
    return PolyOptic.fromRun<Call<Part, E>, Call<TPart, E>, Part, TPart>((update) {
      return (functor) {
        return functor.lmap<TPart>(update);
      };
    });
  }

  static PolyOptic<Result<E, Part>, Result<E, TPart>, Part, TPart> resultSuccess<E, Part, TPart>() {
    return PolyOptic.fromRun<Result<E, Part>, Result<E, TPart>, Part, TPart>((update) {
      return (functor) {
        return functor.rmap<TPart>(update);
      };
    });
  }

  static PolyOptic<Result<Part, E>, Result<TPart, E>, Part, TPart> resultFailure<E, Part, TPart>() {
    return PolyOptic.fromRun<Result<Part, E>, Result<TPart, E>, Part, TPart>((update) {
      return (functor) {
        return functor.lmap<TPart>(update);
      };
    });
  }

  static PolyOptic<These<E, Part>, These<E, TPart>, Part, TPart> theseRight<E, Part, TPart>() {
    return PolyOptic.fromRun<These<E, Part>, These<E, TPart>, Part, TPart>((update) {
      return (functor) {
        return functor.rmap<TPart>(update);
      };
    });
  }

  static PolyOptic<These<Part, E>, These<TPart, E>, Part, TPart> theseLeft<E, Part, TPart>() {
    return PolyOptic.fromRun<These<Part, E>, These<TPart, E>, Part, TPart>((update) {
      return (functor) {
        return functor.lmap<TPart>(update);
      };
    });
  }

  static PolyOptic<(E, Part), (E, TPart), Part, TPart> tupleRight<E, Part, TPart>() {
    return PolyOptic.fromRun<(E, Part), (E, TPart), Part, TPart>((update) {
      return (functor) {
        return functor.rmap<TPart>(update);
      };
    });
  }

  static PolyOptic<(Part, E), (TPart, E), Part, TPart> tupleLeft<E, Part, TPart>() {
    return PolyOptic.fromRun<(Part, E), (TPart, E), Part, TPart>((update) {
      return (functor) {
        return functor.lmap<TPart>(update);
      };
    });
  }

  static PolyOptic<Validator<E, Part>, Validator<E, TPart>, Part, TPart> validatorValue<E, Part, TPart>() {
    return PolyOptic.fromRun<Validator<E, Part>, Validator<E, TPart>, Part, TPart>((update) {
      return (functor) {
        return functor.rmap<TPart>(update);
      };
    });
  }

  static PolyOptic<Validator<Part, E>, Validator<TPart, E>, IList<Part>, IList<TPart>> validatorErrors<E, Part, TPart>() {
    return PolyOptic.fromRun<Validator<Part, E>, Validator<TPart, E>, IList<Part>, IList<TPart>>((update) {
      return (validator) {
        return validator.match<Validator<TPart, E>>(
          (errors) {
            return Validator.errors<TPart, E>(update(errors));
          },
          (value) {
            return Validator.of<TPart, E>(value);
          },
        );
      };
    });
  }

  static PolyOptic<Logger<Part>, Logger<TPart>, Part, TPart> logger<Part, TPart>() {
    return PolyOptic.fromRun<Logger<Part>, Logger<TPart>, Part, TPart>((update) {
      return (functor) {
        return functor.rmap<TPart>(update);
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
