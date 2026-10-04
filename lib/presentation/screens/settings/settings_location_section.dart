import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';

/// A location preset with name and coordinates.
class LocationPreset {
  final String name;
  final double latitude;
  final double longitude;

  const LocationPreset(this.name, this.latitude, this.longitude);
}

/// Location, timezone, and day watermark settings.
class SettingsLocationSection extends ConsumerWidget {
  const SettingsLocationSection({super.key});

  static const List<LocationPreset> _locationPresets = [
    // US West Coast
    LocationPreset('Seattle, WA', 47.6, -122.3),
    LocationPreset('Portland, OR', 45.5, -122.7),
    LocationPreset('San Francisco, CA', 37.8, -122.4),
    LocationPreset('Los Angeles, CA', 34.0, -118.2),
    LocationPreset('San Diego, CA', 32.7, -117.2),
    // US Mountain
    LocationPreset('Denver, CO', 39.7, -105.0),
    LocationPreset('Salt Lake City, UT', 40.8, -111.9),
    LocationPreset('Phoenix, AZ', 33.4, -112.1),
    LocationPreset('Albuquerque, NM', 35.1, -106.6),
    LocationPreset('Las Vegas, NV', 36.2, -115.1),
    LocationPreset('Boise, ID', 43.6, -116.2),
    // US Central
    LocationPreset('Chicago, IL', 41.9, -87.6),
    LocationPreset('Dallas, TX', 32.8, -96.8),
    LocationPreset('Houston, TX', 29.8, -95.4),
    LocationPreset('Minneapolis, MN', 44.9, -93.3),
    LocationPreset('Kansas City, MO', 39.1, -94.6),
    // US East Coast
    LocationPreset('New York, NY', 40.7, -74.0),
    LocationPreset('Boston, MA', 42.4, -71.1),
    LocationPreset('Philadelphia, PA', 40.0, -75.2),
    LocationPreset('Washington, DC', 38.9, -77.0),
    LocationPreset('Miami, FL', 25.8, -80.2),
    LocationPreset('Atlanta, GA', 33.7, -84.4),
    // International
    LocationPreset('London, UK', 51.5, -0.1),
    LocationPreset('Paris, France', 48.9, 2.3),
    LocationPreset('Berlin, Germany', 52.5, 13.4),
    LocationPreset('Tokyo, Japan', 35.7, 139.7),
    LocationPreset('Sydney, Australia', -33.9, 151.2),
    LocationPreset('Toronto, Canada', 43.7, -79.4),
    LocationPreset('Vancouver, Canada', 49.3, -123.1),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Location & Time
        const SectionHeader(title: 'Location & Time'),
        SwitchListTile(
          secondary: const Icon(Icons.wb_sunny_outlined),
          title: const Text('Show Sunrise/Sunset'),
          subtitle: const Text('Display sun times on timeline'),
          value: ref.watch(settingsProvider).showSunTimes,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setShowSunTimes(value);
          },
        ),
        ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Location'),
          subtitle: Text(_getLocationLabel(
            ref.watch(settingsProvider).latitude,
            ref.watch(settingsProvider).longitude,
          )),
          enabled: ref.watch(settingsProvider).showSunTimes,
          onTap: ref.watch(settingsProvider).showSunTimes
              ? () => _showLocationDialog(context, ref)
              : null,
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Timezone'),
          subtitle: Text(_getTimezoneLabel(
              ref.watch(settingsProvider).timezoneOffsetHours)),
          enabled: ref.watch(settingsProvider).showSunTimes,
          onTap: ref.watch(settingsProvider).showSunTimes
              ? () => _showTimezoneDialog(context, ref)
              : null,
        ),

        const Divider(),

        // Day Watermark
        const SectionHeader(title: 'Day Watermark'),
        SwitchListTile(
          secondary: const Icon(Icons.format_list_numbered),
          title: const Text('Week Number'),
          subtitle: const Text('Show W1, W2, etc.'),
          value: ref.watch(settingsProvider).watermarkShowWeekNumber,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .setWatermarkShowWeekNumber(value);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.celebration),
          title: const Text('Holidays'),
          subtitle: const Text('Show US federal holidays'),
          value: ref.watch(settingsProvider).watermarkShowHolidays,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setWatermarkShowHolidays(value);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.nightlight_round),
          title: const Text('Moon Phase'),
          subtitle: const Text('Show current moon phase'),
          value: ref.watch(settingsProvider).watermarkShowMoonPhase,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .setWatermarkShowMoonPhase(value);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.pie_chart_outline),
          title: const Text('Quarter'),
          subtitle: const Text('Show Q1, Q2, Q3, Q4'),
          value: ref.watch(settingsProvider).watermarkShowQuarter,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setWatermarkShowQuarter(value);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.event),
          title: const Text('Day of Year'),
          subtitle: const Text('Show Day 1 through Day 365'),
          value: ref.watch(settingsProvider).watermarkShowDayOfYear,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .setWatermarkShowDayOfYear(value);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.timer_outlined),
          title: const Text('Days Remaining'),
          subtitle: const Text('Show days left in the year'),
          value: ref.watch(settingsProvider).watermarkShowDaysRemaining,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .setWatermarkShowDaysRemaining(value);
          },
        ),
      ],
    );
  }

  String _getTimezoneLabel(double? offset) {
    if (offset == null) {
      final deviceOffset = DateTime.now().timeZoneOffset.inMinutes / 60.0;
      final sign = deviceOffset >= 0 ? '+' : '';
      return 'Auto (UTC$sign${deviceOffset.toStringAsFixed(deviceOffset.truncateToDouble() == deviceOffset ? 0 : 1)})';
    }
    final sign = offset >= 0 ? '+' : '';
    return 'UTC$sign${offset.toStringAsFixed(offset.truncateToDouble() == offset ? 0 : 1)}';
  }

  String _getLocationLabel(double latitude, double longitude) {
    for (final preset in _locationPresets) {
      if ((preset.latitude - latitude).abs() < 0.5 &&
          (preset.longitude - longitude).abs() < 0.5) {
        return preset.name;
      }
    }
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(1)}°$latDir, ${longitude.abs().toStringAsFixed(1)}°$lonDir';
  }

  void _showLocationDialog(BuildContext context, WidgetRef ref) {
    final currentLat = ref.read(settingsProvider).latitude;
    final currentLon = ref.read(settingsProvider).longitude;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _locationPresets.length,
            itemBuilder: (context, index) {
              final preset = _locationPresets[index];
              final isSelected = (preset.latitude - currentLat).abs() < 0.5 &&
                  (preset.longitude - currentLon).abs() < 0.5;
              return ListTile(
                title: Text(preset.name),
                subtitle: Text(
                  '${preset.latitude.abs().toStringAsFixed(1)}°${preset.latitude >= 0 ? 'N' : 'S'}, '
                  '${preset.longitude.abs().toStringAsFixed(1)}°${preset.longitude >= 0 ? 'E' : 'W'}',
                ),
                leading: Radio<bool>(
                  value: true,
                  groupValue: isSelected,
                  onChanged: (_) {
                    ref.read(settingsProvider.notifier).setLocation(
                          preset.latitude,
                          preset.longitude,
                        );
                    Navigator.pop(context);
                  },
                ),
                selected: isSelected,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLocation(
                        preset.latitude,
                        preset.longitude,
                      );
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTimezoneDialog(BuildContext context, WidgetRef ref) {
    final currentOffset = ref.read(settingsProvider).timezoneOffsetHours;

    final timezones = <MapEntry<String, double?>>[
      const MapEntry('Auto-detect from device', null),
      const MapEntry('UTC-12 (Baker Island)', -12),
      const MapEntry('UTC-11 (American Samoa)', -11),
      const MapEntry('UTC-10 (Hawaii)', -10),
      const MapEntry('UTC-9 (Alaska)', -9),
      const MapEntry('UTC-8 (Pacific Time)', -8),
      const MapEntry('UTC-7 (Mountain Time)', -7),
      const MapEntry('UTC-6 (Central Time)', -6),
      const MapEntry('UTC-5 (Eastern Time)', -5),
      const MapEntry('UTC-4 (Atlantic Time)', -4),
      const MapEntry('UTC-3 (Argentina)', -3),
      const MapEntry('UTC-2 (Mid-Atlantic)', -2),
      const MapEntry('UTC-1 (Azores)', -1),
      const MapEntry('UTC+0 (London, GMT)', 0),
      const MapEntry('UTC+1 (Paris, Berlin)', 1),
      const MapEntry('UTC+2 (Athens, Cairo)', 2),
      const MapEntry('UTC+3 (Moscow)', 3),
      const MapEntry('UTC+4 (Dubai)', 4),
      const MapEntry('UTC+5 (Pakistan)', 5),
      const MapEntry('UTC+5:30 (India)', 5.5),
      const MapEntry('UTC+6 (Bangladesh)', 6),
      const MapEntry('UTC+7 (Bangkok)', 7),
      const MapEntry('UTC+8 (Singapore, Perth)', 8),
      const MapEntry('UTC+9 (Tokyo)', 9),
      const MapEntry('UTC+9:30 (Adelaide)', 9.5),
      const MapEntry('UTC+10 (Sydney)', 10),
      const MapEntry('UTC+11 (Solomon Islands)', 11),
      const MapEntry('UTC+12 (Auckland)', 12),
      const MapEntry('UTC+13 (Samoa)', 13),
      const MapEntry('UTC+14 (Line Islands)', 14),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Timezone'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: timezones.length,
            itemBuilder: (context, index) {
              final tz = timezones[index];
              final isSelected = currentOffset == tz.value;
              return ListTile(
                title: Text(tz.key),
                leading: Radio<double?>(
                  value: tz.value,
                  groupValue: currentOffset,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setTimezoneOffsetHours(value);
                    Navigator.pop(context);
                  },
                ),
                selected: isSelected,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setTimezoneOffsetHours(tz.value);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
