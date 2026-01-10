import 'package:flutter/material.dart';
import 'package:timeflow/core/theme/app_colors.dart';

/// Visual states for reminder indicators based on time until reminder triggers.
enum ReminderState {
  /// 15-60 minutes until reminder (faint visibility)
  distant,

  /// 5-15 minutes until reminder (medium visibility)
  approaching,

  /// Less than 5 minutes until reminder (full visibility)
  imminent,

  /// Reminder has triggered (NOW passed reminder time)
  triggered,

  /// User acknowledged the reminder
  acknowledged,
}

/// A subtle dot marker on the timeline showing the reminder time position.
///
/// This is a minimal indicator - the main reminder UI is on the task card itself.
class ReminderDot extends StatelessWidget {
  /// Current state based on time until reminder.
  final ReminderState state;

  const ReminderDot({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show dot if acknowledged
    if (state == ReminderState.acknowledged) {
      return const SizedBox.shrink();
    }

    final color = _getColor();
    final size = _getSize();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: state == ReminderState.triggered || state == ReminderState.imminent
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  Color _getColor() {
    switch (state) {
      case ReminderState.distant:
        return AppColors.reminderLine.withValues(alpha: 0.3);
      case ReminderState.approaching:
        return AppColors.reminderLine.withValues(alpha: 0.6);
      case ReminderState.imminent:
        return AppColors.reminderLine.withValues(alpha: 0.9);
      case ReminderState.triggered:
        return AppColors.reminderLine;
      case ReminderState.acknowledged:
        return Colors.transparent;
    }
  }

  double _getSize() {
    switch (state) {
      case ReminderState.distant:
        return 6;
      case ReminderState.approaching:
        return 8;
      case ReminderState.imminent:
      case ReminderState.triggered:
        return 10;
      case ReminderState.acknowledged:
        return 0;
    }
  }
}
