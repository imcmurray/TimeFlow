import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time, updated at the start of every minute.
///
/// Widgets that only care about minute-level changes (which tasks are past,
/// reminder states) watch this instead of running their own timers, so the
/// timeline rebuilds once a minute rather than every second.
final minuteClockProvider = StreamProvider<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  Timer? timer;
  void schedule() {
    final now = DateTime.now();
    controller.add(now);
    final next =
        DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    timer = Timer(next.difference(now), schedule);
  }

  schedule();
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});

/// [minuteClockProvider]'s latest value, or the actual time before its first
/// event.
DateTime currentMinute(Ref ref) =>
    ref.watch(minuteClockProvider).value ?? DateTime.now();
