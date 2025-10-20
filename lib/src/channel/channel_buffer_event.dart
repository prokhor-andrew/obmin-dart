// Copyright (c) 2024 Andrii Prokhorenko
// This file is part of Obmin, licensed under the MIT License.
// See the LICENSE file in the project root for license information.

part of 'channel_lib.dart';

sealed class ChannelBufferEvent {
  const ChannelBufferEvent();

  bool get isAdded => switch (this) {
        ChannelBufferAddedEvent() => true,
        ChannelBufferRemovedEvent() => false,
      };

  bool get isRemoved => !isAdded;

  @override
  String toString() {
    switch (this) {
      case ChannelBufferAddedEvent():
        return "ChannelBufferAddedEvent";
      case ChannelBufferRemovedEvent(isConsumed: final isConsumed):
        return "ChannelBufferRemovedEvent{ ${isConsumed ? "consumed" : "cancelled"} }";
    }
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChannelBufferEvent && runtimeType == other.runtimeType && isAdded == other.isAdded;

  @override
  int get hashCode => isAdded.hashCode;
}

final class ChannelBufferAddedEvent extends ChannelBufferEvent {}

final class ChannelBufferRemovedEvent extends ChannelBufferEvent {
  final bool isConsumed;

  ChannelBufferRemovedEvent({
    required this.isConsumed,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other && other is ChannelBufferRemovedEvent && runtimeType == other.runtimeType && isAdded == other.isAdded && isConsumed == other.isConsumed;

  @override
  int get hashCode => super.hashCode ^ isConsumed.hashCode;
}
