// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin_dart/obmin_dart.dart';

extension ValidatorOpticExtension<S, A, B> on Optic<S, Validator<A, B>> {
  Optic<S, B> value() {
    return then<B>(Optic.validatorValue<A, B>());
  }

  Optic<S, IList<A>> errors() {
    return then<IList<A>>(Optic.validatorErrors<B, A>());
  }
}

extension ValidatorPathArrowExtension<Whole, A, B> on PathArrow<String, Whole, Validator<A, B>> {
  PathArrow<String, Whole, IList<A>> errors() {
    return then<IList<A>>(PathArrow.validatorErrors<B, A>());
  }

  PathArrow<String, Whole, B> value() {
    return then<B>(PathArrow.validatorValue<A, B>());
  }
}

extension ValidatorOptionArrowExtension<Whole, A, B> on OptionArrow<Whole, Validator<A, B>> {
  OptionArrow<Whole, IList<A>> errors() {
    return then<IList<A>>(OptionArrow.validatorErrors<B, A>());
  }

  OptionArrow<Whole, B> value() {
    return then<B>(OptionArrow.validatorValue<A, B>());
  }
}
