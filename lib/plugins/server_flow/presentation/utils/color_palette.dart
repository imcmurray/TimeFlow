import 'package:flutter/material.dart';

/// A curated 16-color palette for ServerFlow event grouping.
class ColorPalette {
  static const List<Color> colors = [
    Color(0xFF4285F4), // Blue
    Color(0xFFEA4335), // Red
    Color(0xFF34A853), // Green
    Color(0xFFFBBC04), // Yellow
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF6D00), // Orange
    Color(0xFF00BCD4), // Cyan
    Color(0xFFE91E63), // Pink
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF009688), // Teal
    Color(0xFF3F51B5), // Indigo
    Color(0xFFCDDC39), // Lime
    Color(0xFF00E5FF), // Light Cyan
    Color(0xFFFF5252), // Light Red
    Color(0xFF69F0AE), // Light Green
  ];

  /// Returns a deterministic color for a given label string.
  static Color colorForLabel(String label) {
    final hash = label.hashCode.abs();
    return colors[hash % colors.length];
  }

  /// Builds a color map for a list of labels, applying any user overrides.
  static Map<String, Color> buildColorMap(
    List<String> labels, [
    Map<String, Color> overrides = const {},
  ]) {
    final map = <String, Color>{};
    for (final label in labels) {
      map[label] = overrides[label] ?? colorForLabel(label);
    }
    return map;
  }
}
