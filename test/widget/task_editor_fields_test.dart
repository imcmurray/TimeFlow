import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('a value picked in the editor is drawn like one that is typed', (
    tester,
  ) async {
    await pumpApp(tester, const TaskDetailScreen());
    await settle(tester);

    TextStyle styleOf(String text) => tester
        .widget<RichText>(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == text,
          ),
        )
        .text
        .style!;

    // Reminder is a real form field and was never drawn grey; it is the
    // comparison #43 made ("the Reminder field just above it is still dark").
    final reminder = styleOf('10 minutes before');
    expect(reminder.color, AppColors.textPrimary);

    for (final picked in ['None', 'Does not repeat']) {
      final style = styleOf(picked);
      expect(
        style.color,
        reminder.color,
        reason: '"$picked" is a chosen value, so it must not read as a hint',
      );
      expect(style.fontSize, reminder.fontSize, reason: picked);
      expect(style.color, isNot(AppColors.textSecondary), reason: picked);
    }
  });
}
