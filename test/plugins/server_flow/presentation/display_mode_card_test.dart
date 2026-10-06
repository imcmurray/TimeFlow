import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/display_mode_provider.dart';
import 'package:timeflow/plugins/server_flow/presentation/widgets/display_mode_card.dart';

void main() {
  group('DisplayModeInfo extension', () {
    test('individualDots has correct metadata', () {
      expect(DisplayMode.individualDots.displayName, 'Individual Dots');
      expect(DisplayMode.individualDots.description, contains('separate dot'));
      expect(DisplayMode.individualDots.icon, Icons.scatter_plot);
    });

    test('hostSummary has correct metadata', () {
      expect(DisplayMode.hostSummary.displayName, 'By Host');
      expect(DisplayMode.hostSummary.description, contains('host'));
      expect(DisplayMode.hostSummary.icon, Icons.dns_outlined);
    });

    test('timeClusters has correct metadata', () {
      expect(DisplayMode.timeClusters.displayName, 'Clustered');
      expect(DisplayMode.timeClusters.description, contains('clusters'));
      expect(DisplayMode.timeClusters.icon, Icons.bubble_chart);
    });

    test('all modes have non-empty displayName and description', () {
      for (final mode in DisplayMode.values) {
        expect(mode.displayName, isNotEmpty);
        expect(mode.description, isNotEmpty);
      }
    });
  });

  group('DisplayModeCard', () {
    Widget buildCard({
      DisplayMode mode = DisplayMode.individualDots,
      bool isSelected = false,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DisplayModeCard(
            mode: mode,
            isSelected: isSelected,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('renders mode name and description', (tester) async {
      await tester.pumpWidget(buildCard());

      expect(find.text('Individual Dots'), findsOneWidget);
      expect(find.text(DisplayMode.individualDots.description), findsOneWidget);
    });

    testWidgets('renders icon for each mode', (tester) async {
      for (final mode in DisplayMode.values) {
        await tester.pumpWidget(buildCard(mode: mode));
        expect(find.byIcon(mode.icon), findsOneWidget);
      }
    });

    testWidgets('renders CustomPaint preview', (tester) async {
      await tester.pumpWidget(buildCard());
      // The DisplayModeCard contains a CustomPaint with our painter.
      // There may be multiple CustomPaint widgets from the framework,
      // so verify at least one exists inside the card.
      expect(
        find.descendant(
          of: find.byType(DisplayModeCard),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));

      await tester.tap(find.byType(DisplayModeCard));
      expect(tapped, isTrue);
    });

    testWidgets('selected card has primary color border', (tester) async {
      await tester.pumpWidget(buildCard(isSelected: true));

      final materials = tester.widgetList<Material>(
        find.descendant(
          of: find.byType(DisplayModeCard),
          matching: find.byType(Material),
        ),
      );
      final cardMaterial = materials.firstWhere(
        (m) => m.shape is RoundedRectangleBorder,
      );
      final shape = cardMaterial.shape as RoundedRectangleBorder;
      expect(shape.side.width, 2);
    });

    testWidgets('unselected card has thinner border', (tester) async {
      await tester.pumpWidget(buildCard(isSelected: false));

      final materials = tester.widgetList<Material>(
        find.descendant(
          of: find.byType(DisplayModeCard),
          matching: find.byType(Material),
        ),
      );
      final cardMaterial = materials.firstWhere(
        (m) => m.shape is RoundedRectangleBorder,
      );
      final shape = cardMaterial.shape as RoundedRectangleBorder;
      expect(shape.side.width, 1);
    });

    testWidgets('renders all three mode cards in a column', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: DisplayMode.values.map((mode) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DisplayModeCard(
                      mode: mode,
                      isSelected: mode == DisplayMode.hostSummary,
                      onTap: () {},
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DisplayModeCard), findsNWidgets(3));
      expect(find.text('Individual Dots'), findsOneWidget);
      expect(find.text('By Host'), findsOneWidget);
      expect(find.text('Clustered'), findsOneWidget);
    });
  });
}
