// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin_dart/obmin_dart.dart';

extension EitherOpticExtension<S, A, B> on Optic<S, Either<A, B>> {
  Optic<S, A> left() {
    return then<A>(Optic.eitherLeft<B, A>());
  }

  Optic<S, B> right() {
    return then<B>(Optic.eitherRight<A, B>());
  }
}

extension EitherPathArrowExtension<Whole, A, B> on PathArrow<String, Whole, Either<A, B>> {
  PathArrow<String, Whole, A> left() {
    return then<A>(PathArrow.eitherLeft<B, A>());
  }

  PathArrow<String, Whole, B> right() {
    return then<B>(PathArrow.eitherRight<A, B>());
  }
}

extension EitherOptionArrowExtension<Whole, A, B> on OptionArrow<Whole, Either<A, B>> {
  OptionArrow<Whole, A> left() {
    return then<A>(OptionArrow.eitherLeft<B, A>());
  }

  OptionArrow<Whole, B> right() {
    return then<B>(OptionArrow.eitherRight<A, B>());
  }
}
