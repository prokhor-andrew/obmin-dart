// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin/obmin.dart';

extension CallOpticExtension<S, A, B> on Optic<S, Call<A, B>> {
  Optic<S, A> launched() {
    return then<A>(Optic.callLaunched<B, A>());
  }

  Optic<S, B> returned() {
    return then<B>(Optic.callReturned<A, B>());
  }
}

extension CallPathArrowExtension<Whole, A, B> on PathArrow<String, Whole, Call<A, B>> {
  PathArrow<String, Whole, A> launched() {
    return then<A>(PathArrow.callLaunched<B, A>());
  }

  PathArrow<String, Whole, B> returned() {
    return then<B>(PathArrow.callReturned<A, B>());
  }
}

extension CallOptionArrowExtension<Whole, A, B> on OptionArrow<Whole, Call<A, B>> {
  OptionArrow<Whole, A> launched() {
    return then<A>(OptionArrow.callLaunched<B, A>());
  }

  OptionArrow<Whole, B> returned() {
    return then<B>(OptionArrow.callReturned<A, B>());
  }
}
