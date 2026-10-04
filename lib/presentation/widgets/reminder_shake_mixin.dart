import 'package:flutter/material.dart';

/// Mixin that adds a horizontal shake animation for triggered reminders.
///
/// Used by both [TaskCard] and [MergedTaskCard] to indicate a reminder
/// has fired. Requires [SingleTickerProviderStateMixin] on the host.
mixin ReminderShakeMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController shakeController;
  late final Animation<double> shakeAnimation;

  /// Must be called from [initState] of the host widget.
  void initShake() {
    shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    shakeAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: shakeController, curve: Curves.easeInOut),
    );
  }

  /// Must be called from [dispose] of the host widget.
  void disposeShake() {
    shakeController.dispose();
  }

  /// Start or stop the shake animation based on [active].
  void setShakeActive(bool active) {
    if (active) {
      shakeController.repeat(reverse: true);
    } else {
      shakeController.stop();
      shakeController.reset();
    }
  }

  /// Wraps [child] in an [AnimatedBuilder] that applies horizontal shake.
  Widget applyShakeTransform(Widget child) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(shakeAnimation.value, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}
