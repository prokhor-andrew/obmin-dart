// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:obmin/obmin.dart';

final class Optic<Whole, Part> {
  final PolyOptic<Whole, Whole, Part, Part> _optic;

  Func<Whole, Whole> run(Func<Part, Part> update) {
    return _optic.run(update);
  }

  Func<Whole, Whole> set(Part value) => run(constfunc(value));

  const Optic._(this._optic);

  static Optic<Whole, Part> fromPolyOptic<Whole, Part>(PolyOptic<Whole, Whole, Part, Part> polyOptic) {
    return Optic._(polyOptic);
  }

  static Optic<Whole, Part> fromRun<Whole, Part>(Func<Func<Part, Part>, Func<Whole, Whole>> run) {
    return fromPolyOptic<Whole, Part>(PolyOptic.fromRun<Whole, Whole, Part, Part>(run));
  }

  static Optic<T, T> id<T>() {
    return Optic.fromPolyOptic<T, T>(PolyOptic.id<T>());
  }

  static Optic<Whole, Part> adapter<Whole, Part>(Func<Whole, Part> focus, Func<Part, Whole> reconstruct) {
    return Optic.fromPolyOptic<Whole, Part>(PolyOptic.adapter<Whole, Whole, Part, Part>(focus, reconstruct));
  }

  static Optic<Whole, Part> lens<Whole, Part>(Func<Whole, Part> focus, Func<Whole, Func<Part, Whole>> reconstruct) {
    return Optic.fromPolyOptic<Whole, Part>(PolyOptic.lens<Whole, Whole, Part, Part>(focus, reconstruct));
  }

  static Optic<Whole, Part> prism<Whole, Part>(Func<Whole, Option<Part>> focus, Func<Part, Whole> reconstruct) {
    return Optic.fromPolyOptic<Whole, Part>(PolyOptic.prism<Whole, Whole, Part, Part>((whole) => focus(whole).asEither().lmap<Whole>(constfunc<(), Whole>(whole)), reconstruct));
  }

  Optic<Whole, Sub> then<Sub>(Optic<Part, Sub> other) {
    return Optic.fromPolyOptic<Whole, Sub>(_optic.then<Sub, Sub>(other._optic));
  }

  Optic<Whole2, Part> after<Whole2>(Optic<Whole2, Whole> other) {
    return other.then<Part>(this);
  }
}
