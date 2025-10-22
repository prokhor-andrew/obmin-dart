// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class Call<A, B> {
  final Either<A, B> _either;

  const Call._(this._either);

  static Call<A, B> launched<A, B>(A req) => Call._(Either.left<A, B>(req));

  static Call<A, B> returned<A, B>(B res) => Call._(Either.right<A, B>(res));

  static Call<A, ()> unit<A>() => Call.returned<A, ()>(());

  T match<T>(Func<A, T> ifLaunched, Func<B, T> ifReturned) {
    return _either.match<T>(ifLaunched, ifReturned);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Call<A, B>) return false;

    return _either == other._either;
  }

  @override
  int get hashCode => _either.hashCode;

  Call<T, B> lbind<T>(Func<A, Call<T, B>> f) {
    return _either.lbind<T>((val) => f(val)._either).asCall();
  }

  Call<T, B> lmap<T>(Func<A, T> f) {
    return _either.lmap<T>(f).asCall();
  }

  Call<A, T> bind<T>(Func<B, Call<A, T>> f) {
    return _either.bind<T>((val) => f(val)._either).asCall();
  }

  Call<A, T> rmap<T>(Func<B, T> f) {
    return _either.rmap<T>(f).asCall();
  }

  Call<A2, B2> bimap<A2, B2>(Func<A, A2> lf, Func<B, B2> rf) {
    return _either.bimap<A2, B2>(lf, rf).asCall();
  }

  Call<A, (B, T2)> zip<T2>(Call<A, T2> other) {
    return _either.zip<T2>(other._either).asCall();
  }

  Option<A> launchedOrNone() => _either.leftOrNone();

  Option<B> returnedOrNone() => _either.rightOrNone();

  bool isLaunched() => _either.isLeft();

  bool isReturned() => _either.isRight();

  void run(void Function(A value) ifLaunched, void Function(B value) ifReturned) {
    _either.run(ifLaunched, ifReturned);
  }

  void runIfLaunched(void Function(A value) f) {
    _either.runIfLeft(f);
  }

  void runIfReturned(void Function(B value) f) {
    _either.runIfRight(f);
  }

  static Call<E, IList<B>> zipAll<E, B>(IList<Call<E, B>> list) {
    return list.fold<Call<E, IList<B>>>(Call.returned<E, IList<B>>(IList<B>.empty()), (current, element) {
      final call = element.rmap<IList<B>>((value) => [value].lock);
      return current.zip<IList<B>>(call).rmap<IList<B>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }
}

extension CallValueWhenBothExtension<T> on Call<T, T> {
  T value() => match<T>(idfunc<T>, idfunc<T>);
}

extension CallNeverLaunchedExtension<T> on Call<Never, T> {
  T value() => match<T>(absurd<T>, idfunc<T>);
}

extension CallNeverReturnedExtension<T> on Call<T, Never> {
  T value() => match<T>(idfunc<T>, absurd<T>);
}

extension CallMonadExtension<E, T> on Call<E, Call<E, T>> {
  Call<E, T> joined() {
    return bind<T>(idfunc<Call<E, T>>);
  }
}
