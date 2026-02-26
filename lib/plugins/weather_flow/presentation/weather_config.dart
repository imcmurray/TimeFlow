import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the temperature unit preference (Celsius/Fahrenheit).
class WeatherUnitNotifier extends Notifier<bool> {
  static const _key = 'weather_flow_unit';

  @override
  bool build() {
    _load();
    return true; // default: Celsius
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> setUseCelsius(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

/// Provider for the Celsius/Fahrenheit preference.
final weatherUnitProvider = NotifierProvider<WeatherUnitNotifier, bool>(
  WeatherUnitNotifier.new,
);

/// Configuration widget for WeatherFlow — Celsius/Fahrenheit toggle.
class WeatherConfigWidget extends ConsumerWidget {
  const WeatherConfigWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useCelsius = ref.watch(weatherUnitProvider);

    return SwitchListTile(
      title: Text(useCelsius ? 'Celsius' : 'Fahrenheit'),
      subtitle: Text(useCelsius ? 'Showing °C' : 'Showing °F'),
      value: useCelsius,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        ref.read(weatherUnitProvider.notifier).setUseCelsius(value);
      },
    );
  }
}
