import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/services/reminder_actions.dart';

void main() {
  group('the buttons a reminder offers', () {
    test('iOS shows all four, in the order Ian chose', () {
      expect(ReminderActions.onDarwin.map((a) => a.label), [
        'Completed',
        'Snooze 5 min',
        'Snooze 10 min',
        'Dismiss',
      ]);
    });

    test('Android shows three, because three is all it shows', () {
      // Not a preference: Android draws at most three buttons on a
      // notification, and a fourth would simply not appear.
      expect(ReminderActions.onAndroid.length, lessThanOrEqualTo(3));
      expect(ReminderActions.onAndroid.map((a) => a.label), [
        'Completed',
        'Snooze 10 min',
        'Dismiss',
      ]);
    });

    test('and Delete is not one of them, anywhere', () {
      // From a lock screen it would be one mis-tap from losing a task, with no
      // undo. Deleting stays in the app.
      for (final action in ReminderActions.known) {
        expect(action.label.toLowerCase(), isNot(contains('delete')));
      }
    });

    test('every identifier is unique, since it is what comes back', () {
      final ids = ReminderActions.known.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('what an arriving identifier means', () {
    test('Completed completes and Dismiss does not', () {
      expect(ReminderActions.intentOf('completed'), ReminderIntent.complete);
      expect(ReminderActions.intentOf('dismiss'), ReminderIntent.dismiss);
    });

    test('"done" from 1.1.3 (242) still completes the task', () {
      // A reminder already on a lock screen was built by the older build and
      // comes back with its identifier. Dropping it would turn that
      // notification's only useful button into "open the app".
      expect(ReminderActions.intentOf('done'), ReminderIntent.complete);
      expect(
        ReminderActions.onDarwin,
        isNot(contains(ReminderActions.legacyDone)),
      );
      expect(
        ReminderActions.onAndroid,
        isNot(contains(ReminderActions.legacyDone)),
      );
    });

    test('a plain tap, and anything unrecognised, opens the task', () {
      expect(ReminderActions.intentOf(null), ReminderIntent.open);
      expect(ReminderActions.intentOf(''), ReminderIntent.open);
      expect(ReminderActions.intentOf('snooze_30'), ReminderIntent.open);
      expect(ReminderActions.byId('snooze_30'), isNull);
    });

    test(
      'a snooze knows how long for, and nothing else carries a duration',
      () {
        expect(
          ReminderActions.byId('snooze5')!.snooze,
          const Duration(minutes: 5),
        );
        expect(
          ReminderActions.byId('snooze')!.snooze,
          const Duration(minutes: 10),
        );
        for (final action in ReminderActions.known) {
          expect(
            action.snooze == null,
            action.intent != ReminderIntent.snooze,
            reason: action.id,
          );
        }
      },
    );
  });
}
