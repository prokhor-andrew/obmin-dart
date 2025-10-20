// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin_dart/obmin_dart.dart';

extension TupleOpticExtension<S, A, B> on Optic<S, (A, B)> {
  Optic<S, A> left() {
    return then<A>(Optic.tupleLeft<B, A>());
  }

  Optic<S, B> right() {
    return then<B>(Optic.tupleRight<A, B>());
  }
}

extension TuplePathArrowExtension<Whole, A, B> on PathArrow<String, Whole, (A, B)> {
  PathArrow<String, Whole, A> left() {
    return then<A>(PathArrow.tupleLeft<B, A>());
  }

  PathArrow<String, Whole, B> right() {
    return then<B>(PathArrow.tupleRight<A, B>());
  }
}

extension TupleOptionArrowExtension<Whole, A, B> on OptionArrow<Whole, (A, B)> {
  OptionArrow<Whole, A> left() {
    return then<A>(OptionArrow.tupleLeft<B, A>());
  }

  OptionArrow<Whole, B> right() {
    return then<B>(OptionArrow.tupleRight<A, B>());
  }
}
