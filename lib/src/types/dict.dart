// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../func.dart';

extension DictExtensions<Key, A> on IMap<Key, A> {
  IMap<Key, A2> rmap<A2>(Func<A, A2> f) {
    return map<Key, A2>((key, value) => MapEntry(key, f(value)));
  }
}
