// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin/obmin.dart';

extension TupleExtensions<A, B> on (A, B) {
  B extract() => $2;

  (A, (A, B)) duplicate() => ($1, this);

  (A, B2) extend<B2>(Func<(A, B), B2> f) => ($1, f(this));

  (A2, B) lmap<A2>(Func<A, A2> f) {
    return (f($1), $2);
  }

  (A, B2) rmap<B2>(Func<B, B2> f) {
    return ($1, f($2));
  }

  (A2, B2) bimap<A2, B2>(Func<A, A2> lf, Func<B, B2> rf) {
    return lmap<A2>(lf).rmap<B2>(rf);
  }

  (B, A) swapped() {
    return ($2, $1);
  }
}
