import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/plugins/server_flow/presentation/widgets/csv_format_help.dart';

void main() {
  Widget buildWidget() {
    return const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: CsvFormatHelp())),
    );
  }

  group('CsvFormatHelp', () {
    testWidgets('shows "CSV Format" title when collapsed', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('CSV Format'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('does not show column tables when collapsed', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Required Columns'), findsNothing);
      expect(find.text('Optional Columns'), findsNothing);
    });

    testWidgets('shows required column names when expanded', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('CSV Format'));
      await tester.pumpAndSettle();

      expect(find.text('Required Columns'), findsOneWidget);
      expect(find.text('host'), findsOneWidget);
      expect(find.text('command'), findsOneWidget);
      expect(find.text('start_time'), findsOneWidget);
      expect(find.text('user'), findsOneWidget);
    });

    testWidgets('shows optional column names when expanded', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('CSV Format'));
      await tester.pumpAndSettle();

      expect(find.text('Optional Columns'), findsOneWidget);
      expect(find.text('category'), findsOneWidget);
      expect(find.text('duration'), findsOneWidget);
      expect(find.text('schedule'), findsOneWidget);
      expect(find.text('os'), findsOneWidget);
      expect(find.text('end_time'), findsOneWidget);
    });

    testWidgets('shows example CSV block when expanded', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('CSV Format'));
      await tester.pumpAndSettle();

      // "Example" appears in table headers too, so check for the CSV content
      expect(find.textContaining('web-01,/usr/bin/backup'), findsOneWidget);
      expect(find.textContaining('db-01,/opt/vacuum.sh'), findsOneWidget);
      expect(
        find.textContaining('host,command,start_time,user,schedule'),
        findsOneWidget,
      );
    });

    testWidgets('shows notes about end_time and schedule when expanded', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('CSV Format'));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(
        find.text('end_time overrides duration when both are present'),
        findsOneWidget,
      );
      expect(
        find.text('schedule accepts cron expressions (0 2 * * *) or "once"'),
        findsOneWidget,
      );
    });

    testWidgets('shows key rules text when expanded', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('CSV Format'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Column order doesn\'t matter'),
        findsOneWidget,
      );
      expect(find.textContaining('case-insensitive'), findsOneWidget);
      expect(find.textContaining('auto-detected'), findsOneWidget);
    });

    testWidgets('collapses back when tapped again', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Expand
      await tester.tap(find.text('CSV Format'));
      await tester.pumpAndSettle();
      expect(find.text('Required Columns'), findsOneWidget);

      // Collapse
      await tester.tap(find.text('CSV Format'));
      await tester.pumpAndSettle();
      expect(find.text('Required Columns'), findsNothing);
    });
  });
}
