import 'dart:async';

import 'package:flutter/material.dart';

/// Mixin that adds a horizontal shake animation for triggered reminders.
///
/// Used by both [TaskCard] and [MergedTaskCard] to indicate a reminder
/// has fired. Requires [SingleTickerProviderStateMixin] on the host.
mixin ReminderShakeMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController shakeController;
  late final Animation<double> shakeAnimation;
  Timer? _shakeStop;

  /// How long a triggered reminder shakes before settling.
  static const _shakeFor = Duration(seconds: 2);

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
    _shakeStop?.cancel();
    shakeController.dispose();
  }

  /// Shakes briefly when [active] becomes true (skipped when the system asks
  /// for reduced motion), and stops when it's false.
  void setShakeActive(bool active) {
    _shakeStop?.cancel();
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (active && !reduceMotion) {
      shakeController.repeat(reverse: true);
      _shakeStop = Timer(_shakeFor, () {
        if (!mounted) return;
        shakeController.stop();
        shakeController.reset();
      });
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
