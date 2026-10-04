import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/screens/location_picker_screen.dart';
import 'package:timeflow/presentation/screens/settings/choice_dialog.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';
import 'package:timeflow/services/holidays_service.dart';

/// Sunrise/sunset location and the day watermark's contents.
class SettingsLocationSection extends ConsumerWidget {
  const SettingsLocationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final region = HolidayRegion.fromCode(s.holidayRegion);

    return Column(
      children: [
        const SectionHeader(title: 'Sunrise & sunset'),
        SwitchListTile(
          secondary: const Icon(Icons.wb_sunny_outlined),
          title: const Text('Show sunrise and sunset'),
          value: s.showSunTimes,
          onChanged: n.setShowSunTimes,
        ),
        ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Location'),
          subtitle: Text(locationLabel(s, ref.watch(deviceTimeZoneProvider))),
          enabled: s.showSunTimes,
          onTap: s.showSunTimes
              ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LocationPickerScreen(),
                  ),
                )
              : null,
        ),
        const Divider(),
        const SectionHeader(title: 'Day watermark'),
        ListTile(
          leading: const Icon(Icons.celebration_outlined),
          title: const Text('Holidays'),
          subtitle: Text(region.label),
          onTap: () async {
            final picked = await showChoiceDialog<HolidayRegion>(
              context: context,
              title: 'Holiday calendar',
              current: region,
              options: [
                for (final r in HolidayRegion.values) ChoiceOption(r, r.label),
              ],
            );
            if (picked != null) {
              n.setHolidayRegion(picked.name);
              n.setWatermarkShowHolidays(picked != HolidayRegion.none);
            }
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.format_list_numbered),
          title: const Text('Week number'),
          value: s.watermarkShowWeekNumber,
          onChanged: n.setWatermarkShowWeekNumber,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.nightlight_round),
          title: const Text('Moon phase'),
          value: s.watermarkShowMoonPhase,
          onChanged: n.setWatermarkShowMoonPhase,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.pie_chart_outline),
          title: const Text('Quarter'),
          value: s.watermarkShowQuarter,
          onChanged: n.setWatermarkShowQuarter,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.event),
          title: const Text('Day of the year'),
          value: s.watermarkShowDayOfYear,
          onChanged: n.setWatermarkShowDayOfYear,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.timer_outlined),
          title: const Text('Days left in the year'),
          value: s.watermarkShowDaysRemaining,
          onChanged: n.setWatermarkShowDaysRemaining,
        ),
      ],
    );
  }
}
