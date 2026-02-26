import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How to display ServerFlow events on the timeline.
enum DisplayMode { individualDots, hostSummary, timeClusters }

/// Time window for clustering events in [DisplayMode.timeClusters].
enum ClusterWindow {
  fifteenMin(Duration(minutes: 15), '15 min'),
  thirtyMin(Duration(minutes: 30), '30 min'),
  oneHour(Duration(hours: 1), '1 hour');

  final Duration duration;
  final String label;

  const ClusterWindow(this.duration, this.label);
}

/// Holds the current display mode and cluster window setting.
class DisplayModeState {
  final DisplayMode mode;
  final ClusterWindow clusterWindow;

  const DisplayModeState({
    this.mode = DisplayMode.individualDots,
    this.clusterWindow = ClusterWindow.oneHour,
  });

  DisplayModeState copyWith({
    DisplayMode? mode,
    ClusterWindow? clusterWindow,
  }) {
    return DisplayModeState(
      mode: mode ?? this.mode,
      clusterWindow: clusterWindow ?? this.clusterWindow,
    );
  }
}

/// Manages display mode state with SharedPreferences persistence.
class DisplayModeNotifier extends Notifier<DisplayModeState> {
  static const _modeKey = 'server_flow_display_mode';
  static const _windowKey = 'server_flow_cluster_window';

  @override
  DisplayModeState build() {
    _load();
    return const DisplayModeState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_modeKey);
    final windowIndex = prefs.getInt(_windowKey);
    state = DisplayModeState(
      mode: modeIndex != null && modeIndex < DisplayMode.values.length
          ? DisplayMode.values[modeIndex]
          : DisplayMode.individualDots,
      clusterWindow:
          windowIndex != null && windowIndex < ClusterWindow.values.length
              ? ClusterWindow.values[windowIndex]
              : ClusterWindow.oneHour,
    );
  }

  Future<void> setMode(DisplayMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, mode.index);
  }

  Future<void> setClusterWindow(ClusterWindow window) async {
    state = state.copyWith(clusterWindow: window);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_windowKey, window.index);
  }
}

final displayModeProvider =
    NotifierProvider<DisplayModeNotifier, DisplayModeState>(
  DisplayModeNotifier.new,
);
