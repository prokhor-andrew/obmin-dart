// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class Either<A, B> {
  final bool _isRight;
  final A? _left;
  final B? _right;

  const Either._left(A left) : _left = left, _right = null, _isRight = false;

  const Either._right(B right) : _right = right, _left = null, _isRight = true;

  static Either<A, B> left<A, B>(A value) => Either._left(value);

  static Either<A, B> right<A, B>(B value) => Either._right(value);

  static Either<A, ()> unit<A>() => Either.right<A, ()>(());

  T match<T>(Func<A, T> ifLeft, Func<B, T> ifRight) {
    return _isRight ? ifRight(_right as B) : ifLeft(_left as A);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Either<A, B>) return false;

    return match<bool>((left1) => other.match<bool>((left2) => left1 == left2, constfunc<B, bool>(false)), (right1) => other.match<bool>(constfunc<A, bool>(false), (right2) => right1 == right2));
  }

  @override
  int get hashCode => match((value) => value.hashCode, (value) => value.hashCode);

  Either<B, A> swapped() {
    return match<Either<B, A>>(Either.right<B, A>, Either.left<B, A>);
  }

  Either<T, B> lbind<T>(Func<A, Either<T, B>> function) {
    return match<Either<T, B>>(function, Either.right<T, B>);
  }

  Either<A, T> rmap<T>(Func<B, T> f) {
    return match<Either<A, T>>(Either.left<A, T>, (value) => Either.right<A, T>(f(value)));
  }

  Either<T, B> lmap<T>(Func<A, T> f) {
    return swapped().rmap<T>(f).swapped();
  }

  Either<A, T> bind<T>(Func<B, Either<A, T>> f) {
    return match<Either<A, T>>(Either.left<A, T>, f);
  }

  Either<A2, B2> bimap<A2, B2>(Func<A, A2> lf, Func<B, B2> rf) {
    return lmap<A2>(lf).rmap<B2>(rf);
  }

  Either<A, (B, T2)> zip<T2>(Either<A, T2> other) {
    return match<Either<A, (B, T2)>>(Either.left<A, (B, T2)>, (val1) => other.match<Either<A, (B, T2)>>(Either.left<A, (B, T2)>, (val2) => Either.right<A, (B, T2)>((val1, val2))));
  }

  Option<A> leftOrNone() => match<Option<A>>(Option.some<A>, constfunc<B, Option<A>>(Option.none<A>()));

  Option<B> rightOrNone() => swapped().leftOrNone();

  bool isLeft() => leftOrNone().rmap<bool>(constfunc<A, bool>(true)).valueOr(false);

  bool isRight() => !isLeft();

  void run(void Function(A value) ifLeft, void Function(B value) ifRight) {
    match<void Function()>(
      (value) => () {
        ifLeft(value);
      },
      (value) => () {
        ifRight(value);
      },
    )();
  }

  void runIfLeft(void Function(A value) function) {
    run(function, (_) {});
  }

  void runIfRight(void Function(B value) function) {
    swapped().runIfLeft(function);
  }

  static Either<E, IList<B>> zipAll<E, B>(IList<Either<E, B>> list) {
    return list.fold<Either<E, IList<B>>>(Either.right<E, IList<B>>(IList<B>.empty()), (current, element) {
      final either = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(either).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  Result<A, B> asResult() {
    return match<Result<A, B>>(Result.failure<A, B>, Result.success<A, B>);
  }

  Call<A, B> asCall() {
    return match<Call<A, B>>(Call.launched<A, B>, Call.returned<A, B>);
  }
}

extension EitherValueWhenBothExtension<T> on Either<T, T> {
  T value() => match<T>(idfunc<T>, idfunc<T>);
}

extension EitherNeverLeftExtension<T> on Either<Never, T> {
  T value() => match<T>(absurd<T>, idfunc<T>);
}

extension EitherNeverRightExtension<T> on Either<T, Never> {
  T value() => match<T>(idfunc<T>, absurd<T>);
}

extension EitherMonadExtension<E, T> on Either<E, Either<E, T>> {
  Either<E, T> joined() {
    return bind<T>(idfunc<Either<E, T>>);
  }
}
