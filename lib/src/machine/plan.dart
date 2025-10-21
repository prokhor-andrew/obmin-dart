// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin/obmin.dart';

final class Plan<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> {
  final State state;
  final PlanTransition<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> Function(Either<IntTrigger, ExtTrigger>) transit;

  const Plan._({required this.state, required this.transit});

  static Plan<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> create<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect>({
    required State state,
    required PlanTransition<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> Function(State state, Either<IntTrigger, ExtTrigger> trigger) transit,
  }) {
    return Plan._(
      state: state,
      transit: (trigger) {
        return transit(state, trigger);
      },
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Plan<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> && runtimeType == other.runtimeType && state == other.state;
  }

  @override
  int get hashCode => state.hashCode;

  Mealy<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> asMealy(IMap<String, Machine<IntEffect, IntTrigger>> machines) {
    return Mealy.create(
      state: state,
      machines: machines,
      transit: (state, machines, trigger) {
        final transition = transit(trigger);
        return MealyTransition(transition.plan.asMealy(machines), effects: transition.effects);
      },
    );
  }
}

final class PlanTransition<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> {
  final Plan<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> plan;
  final IList<Either<IntEffect, ExtEffect>> effects;

  const PlanTransition(this.plan, {this.effects = const IList.empty()});

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is PlanTransition<State, IntTrigger, IntEffect, ExtTrigger, ExtEffect> && runtimeType == other.runtimeType && plan == other.plan && effects == other.effects;
  }

  @override
  int get hashCode => plan.hashCode ^ effects.hashCode;
}
