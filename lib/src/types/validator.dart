// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class Validator<E, A> {
  final Either<IList<E>, A> _either;

  const Validator._(this._either);

  static Validator<E, A> fromEither<E, A>(Either<IList<E>, A> either) => Validator._(either);

  static Validator<E, A> of<E, A>(A value) => Validator._(Either.right<IList<E>, A>(value));

  static Validator<E, A> error<E, A>(E error) => Validator._(Either.left<IList<E>, A>([error].lock));

  static Validator<E, A> errors<E, A>(IList<E> errors) => Validator._(Either.left<IList<E>, A>(errors));

  static Validator<E, ()> unit<E>() => Validator.of<E, ()>(());

  static Validator<E, Never> zero<E>() => Validator.errors<E, Never>(IList<E>.empty());

  T match<T>(Func<IList<E>, T> ifErrors, Func<A, T> ifValue) {
    return _either.match<T>(ifErrors, ifValue);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Validator<E, A>) return false;

    return match<bool>(
      (errors) => other.match<bool>((errors2) => errors == errors2, constfunc<A, bool>(false)),
      (value) => other.match<bool>(constfunc<IList<E>, bool>(false), (value2) => value == value2),
    );
  }

  @override
  int get hashCode => match<int>((value) => value.hashCode, (value) => value.hashCode);

  Validator<T, A> lmap<T>(Func<E, T> function) {
    return match<Validator<T, A>>((errors) => Validator.errors<T, A>(errors.map<T>(function).toIList()), Validator.of<T, A>);
  }

  Validator<E, T> rmap<T>(Func<A, T> function) {
    return match<Validator<E, T>>(Validator.errors<E, T>, (value) => Validator.of<E, T>(function(value)));
  }

  Validator<E, (A, T2)> zip<T2>(Validator<E, T2> other) {
    return match<Validator<E, (A, T2)>>(
      (errors) {
        return other.match<Validator<E, (A, T2)>>((errors2) => Validator.errors<E, (A, T2)>(errors.addAll(errors2)), (_) => Validator.errors<E, (A, T2)>(errors));
      },
      (value) {
        return other.match<Validator<E, (A, T2)>>(Validator.errors<E, (A, T2)>, (value2) {
          return Validator.of<E, (A, T2)>((value, value2));
        });
      },
    );
  }

  Validator<E, Either<A, T2>> altConcat<T2>(Validator<E, T2> other) {
    return match<Validator<E, Either<A, T2>>>((errors) {
      return other.match<Validator<E, Either<A, T2>>>((errors2) {
        return Validator.errors<E, Either<A, T2>>(errors.addAll(errors2));
      }, (value2) => Validator.of<E, Either<A, T2>>(Either.right<A, T2>(value2)));
    }, (value) => Validator.of<E, Either<A, T2>>(Either.left<A, T2>(value)));
  }

  Validator<E, Either<A, T2>> altLeftBiased<T2>(Validator<E, T2> other) {
    return match<Validator<E, Either<A, T2>>>((errors) {
      return other.match<Validator<E, Either<A, T2>>>((errors2) {
        return Validator.errors<E, Either<A, T2>>(errors);
      }, (value2) => Validator.of<E, Either<A, T2>>(Either.right<A, T2>(value2)));
    }, (value) => Validator.of<E, Either<A, T2>>(Either.left<A, T2>(value)));
  }

  Option<IList<E>> errorsOrNone() => match<Option<IList<E>>>(Option.some<IList<E>>, constfunc<A, Option<IList<E>>>(Option.none<IList<E>>()));

  Option<A> valueOrNone() => match<Option<A>>(constfunc<IList<E>, Option<A>>(Option.none<A>()), Option.some<A>);

  bool isErrors() => errorsOrNone().rmap<bool>(constfunc<IList<E>, bool>(true)).valueOr(false);

  bool isValue() => !isErrors();

  void run(void Function(IList<E> errors) ifErrors, void Function(A value) ifValue) {
    match<void Function()>(
      (errors) => () {
        ifErrors(errors);
      },
      (value) => () {
        ifValue(value);
      },
    )();
  }

  void runIfErrors(void Function(IList<E> errors) function) {
    run(function, (_) {});
  }

  void runIfValue(void Function(A value) function) {
    run((_) {}, function);
  }

  static Validator<E, IList<A>> zipAll<E, A>(IList<Validator<E, A>> list) {
    return list.fold<Validator<E, IList<A>>>(Validator.of<E, IList<A>>(IList<A>.empty()), (current, element) {
      final validator = element.rmap<IList<A>>((value) => [value].lock);
      return current.zip<IList<A>>(validator).rmap<IList<A>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  static Validator<E, (int, A)> altAllConcatTagged<E, A>(IList<Validator<E, A>> list) {
    return list.indexed.fold<Validator<E, (int, A)>>(Validator.errors<E, (int, A)>(IList<E>.empty()), (current, element) {
      final (index, option) = element;
      final validator = option.rmap<(int, A)>((value) => (index, value));
      return current.altConcat<(int, A)>(validator).rmap<(int, A)>((either) {
        return either.value();
      });
    });
  }

  static Validator<E, A> altAllConcat<E, A>(IList<Validator<E, A>> list) {
    return altAllConcatTagged(list).rmap((tuple) => tuple.$2);
  }

  static Validator<E, (int, A)> altAllLeftBiasedTagged<E, A>(IList<Validator<E, A>> list) {
    return list.indexed.fold<Validator<E, (int, A)>>(Validator.errors<E, (int, A)>(IList<E>.empty()), (current, element) {
      final (index, option) = element;
      final validator = option.rmap<(int, A)>((value) => (index, value));
      return current.altLeftBiased<(int, A)>(validator).rmap<(int, A)>((either) {
        return either.value();
      });
    });
  }

  static Validator<E, A> altAllLeftBiased<E, A>(IList<Validator<E, A>> list) {
    return altAllConcatTagged(list).rmap((tuple) => tuple.$2);
  }

  Either<IList<E>, A> asEither() => _either;
}
