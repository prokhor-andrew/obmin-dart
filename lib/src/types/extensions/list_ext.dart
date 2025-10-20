// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin_dart/obmin_dart.dart';

extension IListOpticExtension<S, A> on Optic<S, IList<A>> {
  Optic<S, A> each() {
    return then<A>(Optic.list<A>());
  }

  Optic<S, A> at(int index) {
    return then<A>(
      Optic.fromRun<IList<A>, A>((update) {
        return (whole) {
          if (index < 0 || index >= whole.length) {
            return whole;
          } else {
            final element = whole[index];
            final updated = update(element);
            return whole.replace(index, updated);
          }
        };
      }),
    );
  }

  Optic<S, A> where(Func<A, bool> predicate) {
    return then<A>(
      Optic.fromRun<IList<A>, A>((update) {
        return (whole) {
          return whole.where(predicate).toIList().rmap(update);
        };
      }),
    );
  }
}

extension IListPathArrowExtension<Whole, A> on PathArrow<String, Whole, IList<A>> {
  PathArrow<String, Whole, A> each() {
    return then<A>(PathArrow.list<A>());
  }

  PathArrow<String, Whole, A> at(int index) {
    return then<A>(
      PathArrow.fromRun<String, IList<A>, A>((tuple) {
        final (list) = tuple;
        if (index < 0 || index >= list.length) {
          return Path.empty<String, A>();
        }

        return Path.fromKeyValue("$index", list[index]);
      }),
    );
  }

  PathArrow<String, Whole, A> where(Func<A, bool> predicate) {
    return rmap((list) => list.where(predicate).toIList()).then<A>(PathArrow.list<A>());
  }
}

extension IListOptionArrowExtension<Whole, A> on OptionArrow<Whole, IList<A>> {
  OptionArrow<Whole, A> at(int index) {
    return then<A>(
      OptionArrow.fromRun<IList<A>, A>((list) {
        if (index < 0 || index >= list.length) {
          return Option.none<A>();
        }

        return Option.some(list[index]);
      }),
    );
  }
}
