import 'package:flutter/material.dart';

/// A category people file tasks under, such as *Health* or *Deep Work*.
///
/// Tasks refer to a category by [id]. The 11 built-ins keep the ids they had
/// as enum values before 1.1 (`health`, `deepWork`, ...), so older task rows,
/// backups and share links still match. Categories people add get a
/// generated id. [none] is not stored: it's what a task without a category
/// (or with one that no longer exists) shows as.
@immutable
class TaskCategory {
  final String id;
  final String name;

  /// Key into [categoryIcons].
  final String icon;

  /// ARGB colour.
  final int colorValue;
  final int sortOrder;

  /// One of the categories TimeFlow ships with (it can still be renamed,
  /// recoloured or removed).
  final bool builtIn;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    this.sortOrder = 0,
    this.builtIn = false,
  });

  static const noneId = 'none';

  static const none = TaskCategory(
    id: noneId,
    name: 'None',
    icon: 'circle_outlined',
    colorValue: 0xFF78909C,
    builtIn: true,
  );

  bool get isNone => id == noneId;

  /// Display label for the category.
  String get label => name;

  IconData get iconData => categoryIcons[icon] ?? Icons.label_outline;

  Color get color => Color(colorValue);

  /// Lighter variant of the category color (for backgrounds).
  Color get lightColor => color.withValues(alpha: 0.15);

  /// Whether name, icon and colour are the same as [other]'s.
  bool looksLike(TaskCategory other) =>
      name == other.name &&
      icon == other.icon &&
      colorValue == other.colorValue;

  TaskCategory copyWith({
    String? id,
    String? name,
    String? icon,
    int? colorValue,
    int? sortOrder,
    bool? builtIn,
  }) => TaskCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    colorValue: colorValue ?? this.colorValue,
    sortOrder: sortOrder ?? this.sortOrder,
    builtIn: builtIn ?? this.builtIn,
  );

  @override
  bool operator ==(Object other) =>
      other is TaskCategory &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.colorValue == colorValue &&
      other.sortOrder == sortOrder &&
      other.builtIn == builtIn;

  @override
  int get hashCode =>
      Object.hash(id, name, icon, colorValue, sortOrder, builtIn);

  @override
  String toString() => 'TaskCategory($id, $name)';
}

/// The categories TimeFlow ships with, in their original order. The position
/// of each id in [legacyCategoryOrder] is the index share links have always
/// used, so it must never change.
const builtInCategories = [
  TaskCategory(
    id: 'deepWork',
    name: 'Deep Work',
    icon: 'psychology',
    colorValue: 0xFF5C6BC0,
    sortOrder: 0,
    builtIn: true,
  ),
  TaskCategory(
    id: 'meeting',
    name: 'Meeting',
    icon: 'groups',
    colorValue: 0xFF42A5F5,
    sortOrder: 1,
    builtIn: true,
  ),
  TaskCategory(
    id: 'admin',
    name: 'Admin',
    icon: 'mail_outline',
    colorValue: 0xFF78909C,
    sortOrder: 2,
    builtIn: true,
  ),
  TaskCategory(
    id: 'health',
    name: 'Health',
    icon: 'fitness_center',
    colorValue: 0xFF66BB6A,
    sortOrder: 3,
    builtIn: true,
  ),
  TaskCategory(
    id: 'family',
    name: 'Family',
    icon: 'family_restroom',
    colorValue: 0xFFFF7043,
    sortOrder: 4,
    builtIn: true,
  ),
  TaskCategory(
    id: 'learning',
    name: 'Learning',
    icon: 'school',
    colorValue: 0xFFAB47BC,
    sortOrder: 5,
    builtIn: true,
  ),
  TaskCategory(
    id: 'personal',
    name: 'Personal',
    icon: 'person_outline',
    colorValue: 0xFF26A69A,
    sortOrder: 6,
    builtIn: true,
  ),
  TaskCategory(
    id: 'creative',
    name: 'Creative',
    icon: 'palette',
    colorValue: 0xFFEC407A,
    sortOrder: 7,
    builtIn: true,
  ),
  TaskCategory(
    id: 'travel',
    name: 'Travel',
    icon: 'directions_car',
    colorValue: 0xFFFFA726,
    sortOrder: 8,
    builtIn: true,
  ),
  TaskCategory(
    id: 'rest',
    name: 'Rest',
    icon: 'bedtime',
    colorValue: 0xFF8D6E63,
    sortOrder: 9,
    builtIn: true,
  ),
];

/// Category ids in the order of the pre-1.1 enum, whose index share links
/// carry.
const legacyCategoryOrder = [
  'none',
  'deepWork',
  'meeting',
  'admin',
  'health',
  'family',
  'learning',
  'personal',
  'creative',
  'travel',
  'rest',
];

/// The built-in with [id] as it ships, or null.
TaskCategory? builtInCategory(String id) {
  for (final c in builtInCategories) {
    if (c.id == id) return c;
  }
  return null;
}

/// Icons people can pick for a category. Keyed by name (stored in the
/// database) rather than code point so icon tree shaking keeps working.
const categoryIcons = <String, IconData>{
  'circle_outlined': Icons.circle_outlined,
  'psychology': Icons.psychology,
  'groups': Icons.groups,
  'mail_outline': Icons.mail_outline,
  'fitness_center': Icons.fitness_center,
  'family_restroom': Icons.family_restroom,
  'school': Icons.school,
  'person_outline': Icons.person_outline,
  'palette': Icons.palette,
  'directions_car': Icons.directions_car,
  'bedtime': Icons.bedtime,
  'work_outline': Icons.work_outline,
  'home_outlined': Icons.home_outlined,
  'laptop': Icons.laptop,
  'code': Icons.code,
  'phone': Icons.phone,
  'event': Icons.event,
  'shopping_cart': Icons.shopping_cart_outlined,
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe_outlined,
  'cleaning_services': Icons.cleaning_services_outlined,
  'yard': Icons.yard_outlined,
  'build': Icons.build_outlined,
  'savings': Icons.savings_outlined,
  'directions_run': Icons.directions_run,
  'self_improvement': Icons.self_improvement,
  'spa': Icons.spa_outlined,
  'medical_services': Icons.medical_services_outlined,
  'medication': Icons.medication_outlined,
  'child_care': Icons.child_care,
  'pets': Icons.pets,
  'favorite': Icons.favorite_border,
  'celebration': Icons.celebration_outlined,
  'volunteer_activism': Icons.volunteer_activism_outlined,
  'church': Icons.church_outlined,
  'menu_book': Icons.menu_book,
  'music_note': Icons.music_note,
  'brush': Icons.brush_outlined,
  'videogame': Icons.sports_esports_outlined,
  'sports_soccer': Icons.sports_soccer,
  'park': Icons.park_outlined,
  'flight': Icons.flight,
  'star': Icons.star_border,
};

/// Colours offered when adding or editing a category.
const categoryColors = <int>[
  0xFF5C6BC0, // indigo
  0xFF42A5F5, // blue
  0xFF26C6DA, // cyan
  0xFF26A69A, // teal
  0xFF66BB6A, // green
  0xFF9CCC65, // light green
  0xFFFFCA28, // amber
  0xFFFFA726, // orange
  0xFFFF7043, // deep orange
  0xFFEF5350, // red
  0xFFEC407A, // pink
  0xFFAB47BC, // purple
  0xFF7E57C2, // deep purple
  0xFF8D6E63, // brown
  0xFF78909C, // blue grey
  0xFF616161, // grey
];
