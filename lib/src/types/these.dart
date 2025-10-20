// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin/obmin.dart';

final class These<A, B> {
  final Either<Either<A, B>, (A, B)> _either;

  const These._(this._either);

  static These<A, B> left<A, B>(A value) => These._(Either.left<Either<A, B>, (A, B)>(Either.left<A, B>(value)));

  static These<A, B> right<A, B>(B value) => These._(Either.left<Either<A, B>, (A, B)>(Either.right<A, B>(value)));

  static These<A, B> both<A, B>(A value1, B value2) => These._(Either.right<Either<A, B>, (A, B)>((value1, value2)));

  T match<T>(Func<A, T> ifLeft, Func<B, T> ifRight, BiFunc<A, B, T> ifBoth) {
    return _either.match<T>(
      (either) {
        return either.match<T>(ifLeft, ifRight);
      },
      (both) {
        final (a, b) = both;
        return ifBoth(a, b);
      },
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! These<A, B>) return false;

    return match<bool>(
      (a) => other.match<bool>((a2) => a == a2, constfunc<B, bool>(false), (_, __) => false),
      (b) => other.match<bool>(constfunc<A, bool>(false), (b2) => b == b2, (_, __) => false),
      (a, b) => other.match<bool>(constfunc<A, bool>(false), constfunc<B, bool>(false), (a2, b2) => a == a2 && b == b2),
    );
  }

  @override
  int get hashCode => match<int>((a) => a.hashCode, (b) => b.hashCode, (a, b) => a.hashCode ^ b.hashCode);

  These<B, A> swapped() {
    return match<These<B, A>>(These.right<B, A>, These.left<B, A>, (a, b) => These.both<B, A>(b, a));
  }

  These<A, B2> rmap<B2>(Func<B, B2> f) {
    return match<These<A, B2>>(These.left<A, B2>, (b) => These.right<A, B2>(f(b)), (a, b) => These.both<A, B2>(a, f(b)));
  }

  These<A2, B> lmap<A2>(Func<A, A2> f) {
    return swapped().rmap<A2>(f).swapped();
  }

  These<A2, B2> bimap<A2, B2>(Func<A, A2> lf, Func<B, B2> rf) {
    return lmap<A2>(lf).rmap<B2>(rf);
  }
}
