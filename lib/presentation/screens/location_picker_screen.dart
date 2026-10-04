import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/settings.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/services/cities.dart';

String formatCoordinates(double lat, double lon) =>
    '${lat.abs().toStringAsFixed(2)}°${lat >= 0 ? 'N' : 'S'}, '
    '${lon.abs().toStringAsFixed(2)}°${lon >= 0 ? 'E' : 'W'}';

/// How the sunrise/sunset location reads in settings.
String locationLabel(Settings s, String? timeZone) {
  if (!s.hasChosenLocation) {
    final city = timeZone?.split('/').last.replaceAll('_', ' ');
    return city == null ? 'Automatic' : 'Automatic ($city time zone)';
  }
  for (final c in cities) {
    if ((c.latitude - s.latitude).abs() < 0.01 &&
        (c.longitude - s.longitude).abs() < 0.01) {
      return c.label;
    }
  }
  return formatCoordinates(s.latitude, s.longitude);
}

/// Picks where sunrise and sunset times are calculated for. No location
/// permission: the user picks a city or types coordinates.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _choose(double lat, double lon) {
    ref.read(settingsProvider.notifier).setLocation(lat, lon);
    Navigator.of(context).pop();
  }

  Future<void> _enterCoordinates() async {
    final s = ref.read(settingsProvider);
    final lat = TextEditingController(text: s.latitude.toStringAsFixed(4));
    final lon = TextEditingController(text: s.longitude.toStringAsFixed(4));
    final result = await showDialog<(double, double)>(
      context: context,
      builder: (context) {
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Coordinates'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: lat,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    helperText: '−90 to 90, north positive',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                  ],
                ),
                TextField(
                  controller: lon,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    helperText: '−180 to 180, east positive',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                  ],
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final a = double.tryParse(lat.text);
                  final b = double.tryParse(lon.text);
                  if (a == null || b == null || a.abs() > 90 || b.abs() > 180) {
                    setDialogState(() => error = 'Check the numbers');
                    return;
                  }
                  Navigator.pop(context, (a, b));
                },
                child: const Text('Use these'),
              ),
            ],
          ),
        );
      },
    );
    lat.dispose();
    lon.dispose();
    if (result != null) _choose(result.$1, result.$2);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final q = _query.toLowerCase();
    final matches = q.isEmpty
        ? cities
        : cities
              .where(
                (c) =>
                    c.name.toLowerCase().contains(q) ||
                    c.country.toLowerCase().contains(q),
              )
              .toList();
    bool isCurrent(City c) =>
        s.hasChosenLocation &&
        (c.latitude - s.latitude).abs() < 0.01 &&
        (c.longitude - s.longitude).abs() < 0.01;

    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search cities',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (q.isEmpty) ...[
                  ListTile(
                    leading: Icon(
                      !s.hasChosenLocation
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: const Text('Automatic'),
                    subtitle: const Text('Use the city of your time zone'),
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .useAutomaticLocation();
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_location_alt_outlined),
                    title: const Text('Enter coordinates'),
                    subtitle: s.hasChosenLocation
                        ? Text(formatCoordinates(s.latitude, s.longitude))
                        : null,
                    onTap: _enterCoordinates,
                  ),
                  const Divider(),
                ],
                for (final c in matches)
                  ListTile(
                    leading: Icon(
                      isCurrent(c)
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(c.name),
                    subtitle: Text(c.country),
                    onTap: () => _choose(c.latitude, c.longitude),
                  ),
                if (matches.isEmpty)
                  ListTile(
                    title: const Text('No matching city'),
                    subtitle: const Text('Enter coordinates instead'),
                    onTap: _enterCoordinates,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
