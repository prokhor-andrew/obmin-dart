// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin/obmin.dart';

extension LoggerOpticExtension<S, A> on Optic<S, Logger<A>> {
  Optic<S, A> value() {
    return then<A>(Optic.logger<A>());
  }
}

extension LoggerPathArrowExtension<Whole, A> on PathArrow<String, Whole, Logger<A>> {
  PathArrow<String, Whole, A> value() {
    return then<A>(PathArrow.logger<A>());
  }
}

extension LoggerOptionArrowExtension<Whole, A> on OptionArrow<Whole, Logger<A>> {
  OptionArrow<Whole, A> value() {
    return then<A>(OptionArrow.logger<A>());
  }
}
