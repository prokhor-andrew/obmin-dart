// Copyright (A) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:obmin_dart/obmin_dart.dart';

final class Logger<A> {
  final String _log;
  final A _value;

  const Logger(this._log, this._value);

  String log() => _log;

  A value() => _value;

  static Logger<A> of<A>(A value) => Logger("", value);

  static Logger<()> unit() => Logger.of<()>(());

  Logger<A2> rmap<A2>(Func<A, A2> f) {
    return Logger(_log, f(_value));
  }

  Logger<A2> bind<A2>(Func<A, Logger<A2>> f) {
    final newLogger = f(_value);
    return Logger(_log + newLogger._log, newLogger._value);
  }

  Logger<(A, A2)> zip<A2>(Logger<A2> other) {
    final newLog = _log + other._log;
    return Logger(newLog, (_value, other._value));
  }

  static Logger<IList<A>> zipAll<A>(IList<Logger<A>> list) {
    return list.fold<Logger<IList<A>>>(Logger.of<IList<A>>(IList<A>.empty()), (current, element) {
      final logger = element.rmap<IList<A>>((value) => [value].lock);
      return current.zip<IList<A>>(logger).rmap<IList<A>>((tuple) => tuple.$1.addAll(tuple.$2));
    });
  }

  (String, A) asTuple() {
    return (_log, _value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Logger<A>) {
      return false;
    }

    return _log == other._log && _value == other._value;
  }

  @override
  int get hashCode => _log.hashCode ^ _value.hashCode;
}

extension LoggerMonadExtension<T> on Logger<Logger<T>> {
  Logger<T> joined() {
    return bind<T>(idfunc<Logger<T>>);
  }
}
