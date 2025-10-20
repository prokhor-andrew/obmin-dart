// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin/obmin.dart';

extension TheseOpticExtension<S, A, B> on Optic<S, These<A, B>> {
  Optic<S, B> right() {
    return then<B>(Optic.theseRight<A, B>());
  }

  Optic<S, A> left() {
    return then<A>(Optic.theseLeft<B, A>());
  }
}

extension ThesePathArrowExtension<Whole, A, B> on PathArrow<String, Whole, These<A, B>> {
  PathArrow<String, Whole, A> left() {
    return then<A>(PathArrow.theseLeft<B, A>());
  }

  PathArrow<String, Whole, B> right() {
    return then<B>(PathArrow.theseRight<A, B>());
  }
}

extension TheseOptionArrowExtension<Whole, A, B> on OptionArrow<Whole, These<A, B>> {
  OptionArrow<Whole, A> left() {
    return then<A>(OptionArrow.theseLeft<B, A>());
  }

  OptionArrow<Whole, B> right() {
    return then<B>(OptionArrow.theseRight<A, B>());
  }
}
