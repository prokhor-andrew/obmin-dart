// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

typedef Func<A, B> = B Function(A);
typedef BiFunc<A, B, C> = C Function(A, B);

typedef Endo<A> = Func<A, A>;

A idfunc<A>(A value) => value;

A absurd<A>(Never v) => v;

Func<A, B> constfunc<A, B>(B value) {
  return (_) => value;
}

Func<A, Func<B, C>> curry<A, B, C>(BiFunc<A, B, C> f) {
  return (a) => (b) => f(a, b);
}

BiFunc<A, B, C> uncurry<A, B, C>(Func<A, Func<B, C>> f) {
  return (a, b) => f(a)(b);
}

Func<A, C> thenf<A, B, C>(Func<A, B> lf, Func<B, C> rf) => (a) => rf(lf(a));

// procedure

typedef Procedure = void Function();

void noop() {}

Procedure thenp(Procedure l, Procedure r) => () {
      l();
      r();
    };
