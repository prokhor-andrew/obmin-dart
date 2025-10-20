// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

part of 'channel_lib.dart';

final class ChannelBufferStrategy<T> {
  final String id;
  final List<ChannelBufferData<T>> Function(List<ChannelBufferData<T>> data, ChannelBufferEvent event) bufferReducer;

  const ChannelBufferStrategy({
    required this.id,
    required this.bufferReducer,
  });

  static ChannelBufferStrategy<T> defaultStrategy<T>({
    required String id,
  }) {
    return ChannelBufferStrategy<T>(
      id: id,
      bufferReducer: (data, event) {
        return data;
      },
    );
  }

  @override
  String toString() {
    return "ChannelBufferStrategy<$T>{ id=$id }";
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChannelBufferStrategy<T> && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
