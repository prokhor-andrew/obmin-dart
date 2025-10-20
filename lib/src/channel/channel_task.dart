// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

part of 'channel_lib.dart';

final class ChannelTask<T> {
  final String id;
  final Future<T> future;
  final void Function() cancel;

  const ChannelTask({
    required this.id,
    required this.future,
    required this.cancel,
  });

  @override
  String toString() {
    return "$ChannelTask<$T> id=$id";
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChannelTask<T> && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
