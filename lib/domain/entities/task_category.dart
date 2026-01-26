import 'package:flutter/material.dart';

/// Categories for organizing tasks by type of activity.
///
/// Each category has an associated icon, color, and label
/// to help users quickly identify the nature of their tasks.
enum TaskCategory {
  /// No specific category assigned.
  none,

  /// Deep, focused work requiring concentration.
  deepWork,

  /// Meetings and collaborative sessions.
  meeting,

  /// Administrative tasks like email, paperwork.
  admin,

  /// Health and fitness activities.
  health,

  /// Family and relationship time.
  family,

  /// Learning and education.
  learning,

  /// Personal errands and chores.
  personal,

  /// Creative work and hobbies.
  creative,

  /// Travel and commute time.
  travel,

  /// Breaks and rest periods.
  rest,
}

/// Extension providing display properties for TaskCategory.
extension TaskCategoryExtension on TaskCategory {
  /// Display label for the category.
  String get label {
    switch (this) {
      case TaskCategory.none:
        return 'None';
      case TaskCategory.deepWork:
        return 'Deep Work';
      case TaskCategory.meeting:
        return 'Meeting';
      case TaskCategory.admin:
        return 'Admin';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.family:
        return 'Family';
      case TaskCategory.learning:
        return 'Learning';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.creative:
        return 'Creative';
      case TaskCategory.travel:
        return 'Travel';
      case TaskCategory.rest:
        return 'Rest';
    }
  }

  /// Icon representing the category.
  IconData get icon {
    switch (this) {
      case TaskCategory.none:
        return Icons.circle_outlined;
      case TaskCategory.deepWork:
        return Icons.psychology;
      case TaskCategory.meeting:
        return Icons.groups;
      case TaskCategory.admin:
        return Icons.mail_outline;
      case TaskCategory.health:
        return Icons.fitness_center;
      case TaskCategory.family:
        return Icons.family_restroom;
      case TaskCategory.learning:
        return Icons.school;
      case TaskCategory.personal:
        return Icons.person_outline;
      case TaskCategory.creative:
        return Icons.palette;
      case TaskCategory.travel:
        return Icons.directions_car;
      case TaskCategory.rest:
        return Icons.bedtime;
    }
  }

  /// Primary color for the category.
  Color get color {
    switch (this) {
      case TaskCategory.none:
        return const Color(0xFF78909C); // Blue grey
      case TaskCategory.deepWork:
        return const Color(0xFF5C6BC0); // Indigo
      case TaskCategory.meeting:
        return const Color(0xFF42A5F5); // Blue
      case TaskCategory.admin:
        return const Color(0xFF78909C); // Blue grey
      case TaskCategory.health:
        return const Color(0xFF66BB6A); // Green
      case TaskCategory.family:
        return const Color(0xFFFF7043); // Deep orange
      case TaskCategory.learning:
        return const Color(0xFFAB47BC); // Purple
      case TaskCategory.personal:
        return const Color(0xFF26A69A); // Teal
      case TaskCategory.creative:
        return const Color(0xFFEC407A); // Pink
      case TaskCategory.travel:
        return const Color(0xFFFFA726); // Orange
      case TaskCategory.rest:
        return const Color(0xFF8D6E63); // Brown
    }
  }

  /// Lighter variant of the category color (for backgrounds).
  Color get lightColor {
    return color.withOpacity(0.15);
  }

  /// Serialize to string for storage.
  String get value => name;

  /// Parse from string.
  static TaskCategory fromString(String? value) {
    if (value == null) return TaskCategory.none;
    try {
      return TaskCategory.values.firstWhere(
        (c) => c.name == value,
        orElse: () => TaskCategory.none,
      );
    } catch (_) {
      return TaskCategory.none;
    }
  }
}

/// Widget displaying a category chip/badge.
class CategoryBadge extends StatelessWidget {
  final TaskCategory category;
  final bool compact;
  final VoidCallback? onTap;

  const CategoryBadge({
    super.key,
    required this.category,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (category == TaskCategory.none) {
      return const SizedBox.shrink();
    }

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: category.lightColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: category.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            size: compact ? 12 : 16,
            color: category.color,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: category.color,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }
}

/// Dropdown selector for task categories.
class CategorySelector extends StatelessWidget {
  final TaskCategory value;
  final ValueChanged<TaskCategory?> onChanged;

  const CategorySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TaskCategory>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: TaskCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 20,
                color: category == TaskCategory.none
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : category.color,
              ),
              const SizedBox(width: 12),
              Text(category.label),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
