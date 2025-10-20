// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin/obmin.dart';

extension OptionOpticExtension<S, A> on Optic<S, Option<A>> {
  Optic<S, A> some() {
    return then<A>(Optic.option<A>());
  }
}

extension OptionPathArrowExtension<Whole, A> on PathArrow<String, Whole, Option<A>> {
  PathArrow<String, Whole, A> some() {
    return then<A>(PathArrow.option<A>());
  }
}

extension OptionOptionArrowExtension<Whole, A> on OptionArrow<Whole, Option<A>> {
  OptionArrow<Whole, A> some() {
    return then<A>(OptionArrow.option<A>());
  }
}
