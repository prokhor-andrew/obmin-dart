// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

part of 'channel_lib.dart';

final class ChannelBufferData<T> {
  final String id;
  final T data;
  final Completer<bool> _completer;

  const ChannelBufferData._({
    required this.id,
    required this.data,
    required Completer<bool> completer,
  }) : _completer = completer;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChannelBufferData<T> && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChannelBufferData<$T>{ id=$id _ data=$data }';
  }
}
