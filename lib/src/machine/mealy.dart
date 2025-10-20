// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin_dart/obmin_dart.dart';

final class Mealy<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> {
  final State state;
  final IMap<String, Machine<IntEffect, IntTrigger>> machines;

  final MealyTransition<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> Function(Either<IntTrigger, ExtTrigger> event) transit;

  const Mealy._({
    required this.state,
    required this.machines,
    required this.transit,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Mealy<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> && other.state == state && other.machines.keys == machines.keys;
  }

  @override
  int get hashCode => state.hashCode ^ machines.keys.hashCode;

  static Mealy<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> create<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect>({
    required State state,
    required IMap<String, Machine<IntEffect, IntTrigger>> machines,
    required MealyTransition<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> Function(
      State state,
      IMap<String, Machine<IntEffect, IntTrigger>> machines,
      Either<IntTrigger, ExtTrigger> trigger,
    ) transit,
  }) {
    return Mealy._(
      state: state,
      machines: machines,
      transit: (trigger) {
        return transit(
          state,
          machines,
          trigger,
        );
      },
    );
  }
}

final class MealyTransition<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> {
  final Mealy<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> mealy;
  final IList<Either<IntEffect, ExtEffect>> effects;

  const MealyTransition(
    this.mealy, {
    this.effects = const IList.empty(),
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MealyTransition<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> && other.mealy == mealy && other.effects == effects;
  }

  @override
  int get hashCode => mealy.hashCode ^ effects.hashCode;
}
