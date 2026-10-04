import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';

/// Generates demo weather events for any date range.
class StaticWeatherData {
  /// Whether to display temperatures in Celsius (true) or Fahrenheit (false).
  final bool useCelsius;

  const StaticWeatherData({this.useCelsius = true});

  /// Generates weather events every 3 hours for the given date range.
  List<TimelineEvent> generate(DateTime from, DateTime until) {
    final events = <TimelineEvent>[];
    var current = DateTime(from.year, from.month, from.day);

    while (current.isBefore(until)) {
      for (var hour = 0; hour < 24; hour += 3) {
        final eventTime = DateTime(
          current.year,
          current.month,
          current.day,
          hour,
        );
        if (eventTime.isBefore(from) || eventTime.isAfter(until)) continue;

        // Sinusoidal temperature peaking at 14:00
        final tempC = _temperatureForHour(hour, current.day);
        final displayTemp = useCelsius ? tempC : _toFahrenheit(tempC);
        final unit = useCelsius ? 'C' : 'F';
        final condition = _conditionForHour(hour);
        final humidity = _humidityForHour(hour);
        final color = _colorForTemp(tempC);

        events.add(TimelineEvent(
          id: 'weather_${eventTime.toIso8601String()}',
          pluginId: 'weather_flow',
          title: '${displayTemp.round()}°$unit  $condition',
          subtitle: 'Humidity: $humidity%',
          startTime: eventTime,
          color: color,
          metadata: {
            'temperature': '${displayTemp.round()}°$unit',
            'condition': condition,
            'humidity': '$humidity%',
          },
        ));
      }
      current = current.add(const Duration(days: 1));
    }

    return events;
  }

  /// Sinusoidal temperature curve peaking at 14:00.
  /// Base ~15°C, amplitude ~10°C. Day-of-month adds minor variation.
  double _temperatureForHour(int hour, int dayOfMonth) {
    final phase = (hour - 14) * pi / 12.0;
    final base = 15.0 + (dayOfMonth % 5) - 2; // slight daily variation
    return base + 10.0 * cos(phase);
  }

  double _toFahrenheit(double celsius) => celsius * 9 / 5 + 32;

  String _conditionForHour(int hour) {
    if (hour >= 6 && hour < 10) return 'Partly Cloudy';
    if (hour >= 10 && hour < 16) return 'Sunny';
    if (hour >= 16 && hour < 19) return 'Partly Cloudy';
    if (hour >= 19 && hour < 22) return 'Clear';
    return 'Clear Night';
  }

  int _humidityForHour(int hour) {
    // Higher humidity in morning and evening
    if (hour < 6) return 75;
    if (hour < 10) return 65;
    if (hour < 16) return 40;
    if (hour < 20) return 55;
    return 70;
  }

  /// Temperature color scale: blue (cold) → amber (warm) → red (hot).
  Color _colorForTemp(double celsius) {
    if (celsius < 5) return Colors.blue.shade700;
    if (celsius < 10) return Colors.blue.shade400;
    if (celsius < 15) return Colors.cyan;
    if (celsius < 20) return Colors.amber.shade400;
    if (celsius < 25) return Colors.amber.shade700;
    return Colors.red.shade600;
  }
}
