// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

extension WriterOpticExtension<S, A, B> on Optic<S, Writer<A, B>> {
  Optic<S, IList<A>> list() {
    return then<IList<A>>(Optic.writerList<B, A>());
  }

  Optic<S, B> value() {
    return then<B>(Optic.writerValue<A, B>());
  }
}

extension WriterPathArrowExtension<Whole, A, B> on PathArrow<String, Whole, Writer<A, B>> {
  PathArrow<String, Whole, IList<A>> list() {
    return then<IList<A>>(PathArrow.writerList<B, A>());
  }

  PathArrow<String, Whole, B> value() {
    return then<B>(PathArrow.writerValue<A, B>());
  }
}

extension WriterOptionArrowExtension<Whole, A, B> on OptionArrow<Whole, Writer<A, B>> {
  OptionArrow<Whole, IList<A>> list() {
    return then<IList<A>>(OptionArrow.writerList<B, A>());
  }

  OptionArrow<Whole, B> value() {
    return then<B>(OptionArrow.writerValue<A, B>());
  }
}
