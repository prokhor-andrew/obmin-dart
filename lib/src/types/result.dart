// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class Result<A, B> {
  final Either<A, B> _either;

  const Result._(this._either);

  static Result<A, B> failure<A, B>(A err) => Result._(Either.left<A, B>(err));

  static Result<A, B> success<A, B>(B val) => Result._(Either.right<A, B>(val));

  static Result<A, ()> unit<A>() => Result.success<A, ()>(());

  T match<T>(Func<A, T> ifFailure, Func<B, T> ifSuccess) {
    return _either.match<T>(ifFailure, ifSuccess);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Result<A, B>) return false;

    return _either == other._either;
  }

  @override
  int get hashCode => _either.hashCode;

  Result<T, B> rescue<T>(Func<A, Result<T, B>> f) {
    return _either.rescue<T>((val) => f(val)._either).asResult();
  }

  Result<T, B> lmap<T>(Func<A, T> f) {
    return _either.lmap<T>(f).asResult();
  }

  Result<A, T> bind<T>(Func<B, Result<A, T>> f) {
    return _either.bind<T>((val) => f(val)._either).asResult();
  }

  Result<A, T> rmap<T>(Func<B, T> f) {
    return _either.rmap<T>(f).asResult();
  }

  Result<A2, B2> bimap<A2, B2>(Func<A, A2> lf, Func<B, B2> rf) {
    return _either.bimap<A2, B2>(lf, rf).asResult();
  }

  Result<A, (B, T2)> zip<T2>(Result<A, T2> other) {
    return _either.zip<T2>(other._either).asResult();
  }

  Option<A> failureOrNone() => _either.leftOrNone();

  Option<B> successOrNone() => _either.rightOrNone();

  bool isFailure() => _either.isLeft();

  bool isSuccess() => _either.isRight();

  void run(void Function(A value) ifFailure, void Function(B value) ifSuccess) {
    _either.run(ifFailure, ifSuccess);
  }

  void runIfFailure(void Function(A value) f) {
    _either.runIfLeft(f);
  }

  void runIfSuccess(void Function(B value) f) {
    _either.runIfRight(f);
  }

  static Result<E, IList<B>> zipAll<E, B>(IList<Result<E, B>> list) {
    return list.fold<Result<E, IList<B>>>(Result.success<E, IList<B>>(IList<B>.empty()), (current, element) {
      final result = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(result).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  These<A, B> asThese() {
    return match<These<A, B>>(These.left<A, B>, These.right<A, B>);
  }

  Either<A, B> asEither() {
    return _either;
  }
}

extension ResultValueWhenBothExtension<T> on Result<T, T> {
  T value() => match<T>(idfunc<T>, idfunc<T>);

  IList<T> asIList() {
    return [value()].lock;
  }

  Logger<T> asLogger() {
    return Logger.of<T>(value());
  }

  Writer<E, T> asWriter<E>() {
    return Writer.of<E, T>(value());
  }
}

extension ResultNeverFailureExtension<T> on Result<Never, T> {
  T value() => match<T>(absurd<T>, idfunc<T>);

  IList<T> asIList() {
    return [value()].lock;
  }
}

extension ResultNeverSuccessExtension<T> on Result<T, Never> {
  T value() => match<T>(idfunc<T>, absurd<T>);
}

extension ResultUnitFailureExtension<T> on Result<(), T> {
  Option<T> asOption() {
    return match<Option<T>>(constfunc<(), Option<T>>(Option.none<T>()), Option.some<T>);
  }

  IList<T> asList() {
    return match<IList<T>>(constfunc<(), IList<T>>(IList<T>.empty()), (value) => [value].lock);
  }
}

extension ResultListFailureExtension<E, T> on Result<IList<E>, T> {
  Validator<E, T> asValidator() {
    return match<Validator<E, T>>(Validator.errors<E, T>, Validator.of<E, T>);
  }
}

extension ResultMonadExtension<E, T> on Result<E, Result<E, T>> {
  Result<E, T> joined() {
    return bind<T>(idfunc<Result<E, T>>);
  }
}
