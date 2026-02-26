import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How to group/color ServerFlow events.
enum GroupingMode { host, category, user }

/// State for the grouping and coloring system.
class GroupingState {
  final GroupingMode mode;
  final Map<String, Color> colorOverrides;

  const GroupingState({
    this.mode = GroupingMode.host,
    this.colorOverrides = const {},
  });

  GroupingState copyWith({
    GroupingMode? mode,
    Map<String, Color>? colorOverrides,
  }) {
    return GroupingState(
      mode: mode ?? this.mode,
      colorOverrides: colorOverrides ?? this.colorOverrides,
    );
  }
}

/// Manages the grouping mode and color overrides.
class GroupingNotifier extends Notifier<GroupingState> {
  @override
  GroupingState build() => const GroupingState();

  void setMode(GroupingMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setColorOverride(String label, Color color) {
    final overrides = Map<String, Color>.from(state.colorOverrides);
    overrides[label] = color;
    state = state.copyWith(colorOverrides: overrides);
  }

  void clearColorOverride(String label) {
    final overrides = Map<String, Color>.from(state.colorOverrides);
    overrides.remove(label);
    state = state.copyWith(colorOverrides: overrides);
  }
}

final groupingProvider =
    NotifierProvider<GroupingNotifier, GroupingState>(GroupingNotifier.new);
