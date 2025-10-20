// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin_dart/obmin_dart.dart';

final class Option<T> {
  final Either<(), T> _either;

  const Option._(this._either);

  static Option<A> some<A>(A value) => Option._(Either.right<(), A>(value));

  static Option<A> none<A>() => Option._(Either.left<(), A>(()));

  static Option<()> unit() => Option.some<()>(());

  static Option<Never> zero() => Option.none<Never>();

  V match<V>(V Function() ifNone, Func<T, V> ifSome) {
    return _either.match<V>((_) => ifNone(), ifSome);
  }

  Either<(), T> asEither() {
    return _either;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Option<T>) return false;

    return match<bool>(() => other.match<bool>(() => true, constfunc<T, bool>(false)), (val) => other.match<bool>(() => false, (val2) => val == val2));
  }

  @override
  int get hashCode => match<int>(() => 0, (val) => val.hashCode);

  Option<(T, R)> zip<R>(Option<R> other) {
    return match<Option<(T, R)>>(Option.none<(T, R)>, (val1) => other.match<Option<(T, R)>>(Option.none<(T, R)>, (val2) => Option.some<(T, R)>((val1, val2))));
  }

  Option<R> bind<R>(Func<T, Option<R>> function) {
    return match<Option<R>>(Option.none<R>, function);
  }

  Option<R> rmap<R>(Func<T, R> f) {
    return bind<R>((value) {
      return Option.some<R>(f(value));
    });
  }

  T valueOr(T replacement) {
    return match<T>(() => replacement, idfunc<T>);
  }

  bool isSome() => rmap<bool>(constfunc<T, bool>(true)).valueOr(false);

  bool isNone() => !isSome();

  void run(void Function() ifNone, void Function(T value) ifSome) {
    match<void Function()>(
      () => ifNone,
      (value) => () {
        ifSome(value);
      },
    )();
  }

  void runIfSome(void Function(T value) function) {
    run(() {}, function);
  }

  void runIfNone(void Function() function) {
    run(function, (_) {});
  }

  Option<Either<T, T2>> alt<T2>(Option<T2> other) {
    return match<Option<Either<T, T2>>>(() => other.rmap<Either<T, T2>>(Either.right<T, T2>), (value) => Option.some<Either<T, T2>>(Either.left<T, T2>(value)));
  }

  static Option<IList<T>> zipAll<T>(IList<Option<T>> list) {
    return list.fold<Option<IList<T>>>(Option.some<IList<T>>(IList<T>.empty()), (current, element) {
      final option = element.rmap<IList<T>>((value) => [value].lock);
      return current.zip<IList<T>>(option).rmap<IList<T>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  static Option<(int, T)> altAllTagged<T>(IList<Option<T>> list) {
    return list.indexed.fold<Option<(int, T)>>(Option.none<(int, T)>(), (current, element) {
      final (index, option) = element;
      final indexedOption = option.rmap<(int, T)>((value) => (index, value));
      return current.alt<(int, T)>(indexedOption).rmap<(int, T)>((either) {
        return either.value();
      });
    });
  }

  static Option<T> altAll<T>(IList<Option<T>> list) {
    return altAllTagged(list).rmap((tuple) => tuple.$2);
  }

  Validator<(), T> asValidator() {
    return match<Validator<(), T>>(() {
      return Validator.errors<(), T>(const IList<()>.empty());
    }, Validator.of<(), T>);
  }

  IList<T> asList() {
    return match<IList<T>>(() => IList<T>.empty(), (value) => [value].lock);
  }

  These<(), T> asThese() {
    return match<These<(), T>>(() => These.left<(), T>(()), These.right<(), T>);
  }
}

extension EitherToOptionalExtension<T> on Either<(), T> {
  Option<T> asOption() {
    return match<Option<T>>(constfunc<(), Option<T>>(Option.none<T>()), Option.some<T>);
  }
}

extension OptionMonadExtension<T> on Option<Option<T>> {
  Option<T> joined() {
    return bind<T>(idfunc<Option<T>>);
  }
}
