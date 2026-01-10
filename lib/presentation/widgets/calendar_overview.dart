import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';

/// Calendar overview showing multiple months for quick date navigation.
///
/// Displays a scrollable list of months with task indicators on dates
/// that have scheduled tasks. Tapping a date triggers navigation to that day.
class CalendarOverview extends ConsumerStatefulWidget {
  /// The month to initially center on.
  final DateTime initialMonth;

  /// Called when a date is selected.
  final ValueChanged<DateTime> onDateSelected;

  const CalendarOverview({
    super.key,
    required this.initialMonth,
    required this.onDateSelected,
  });

  @override
  ConsumerState<CalendarOverview> createState() => _CalendarOverviewState();
}

class _CalendarOverviewState extends ConsumerState<CalendarOverview> {
  late final PageController _pageController;

  // Show 24 months before and after current month
  static const int _monthsBeforeToday = 24;
  static const int _monthsAfterToday = 24;
  static const int _totalMonths = _monthsBeforeToday + _monthsAfterToday + 1;

  late DateTime _baseMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _pageController = PageController(
      initialPage: _monthsBeforeToday,
      viewportFraction: 0.85,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getMonthForIndex(int index) {
    final monthOffset = index - _monthsBeforeToday;
    return DateTime(_baseMonth.year, _baseMonth.month + monthOffset);
  }

  @override
  Widget build(BuildContext context) {
    final datesWithTasks = ref.watch(datesWithTasksProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Month navigation with arrow buttons
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                tooltip: 'Previous month',
              ),
              Text(
                'Browse months',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                tooltip: 'Next month',
              ),
            ],
          ),
        ),

        // Month pages
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _totalMonths,
            itemBuilder: (context, index) {
              final month = _getMonthForIndex(index);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _MonthGrid(
                  month: month,
                  datesWithTasks: datesWithTasks,
                  onDateSelected: widget.onDateSelected,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A single month grid showing all days.
class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Set<DateTime> datesWithTasks;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthGrid({
    required this.month,
    required this.datesWithTasks,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Month header
    final monthName = _formatMonth(month);
    final isCurrentMonth = month.year == today.year && month.month == today.month;

    // Calculate days in month and starting weekday
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    return Card(
      elevation: isCurrentMonth ? 4 : 1,
      color: isCurrentMonth
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month header
            Text(
              monthName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isCurrentMonth ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                return SizedBox(
                  width: 36,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Day grid using Column/Row (no scrollables)
            Expanded(
              child: Column(
                children: _buildWeekRows(
                  month: month,
                  today: today,
                  daysInMonth: daysInMonth,
                  startingWeekday: startingWeekday,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeekRows({
    required DateTime month,
    required DateTime today,
    required int daysInMonth,
    required int startingWeekday,
    required ColorScheme colorScheme,
  }) {
    final rows = <Widget>[];
    int dayCounter = 1 - (startingWeekday - 1);

    for (int week = 0; week < 6; week++) {
      final cells = <Widget>[];
      for (int weekday = 0; weekday < 7; weekday++) {
        if (dayCounter < 1 || dayCounter > daysInMonth) {
          cells.add(const Expanded(child: SizedBox()));
        } else {
          final date = DateTime(month.year, month.month, dayCounter);
          final isToday = date == today;
          final hasTask = datesWithTasks.contains(date);
          final day = dayCounter;
          cells.add(
            Expanded(
              child: _DayButton(
                day: day,
                isToday: isToday,
                hasTask: hasTask,
                onTap: () => onDateSelected(date),
              ),
            ),
          );
        }
        dayCounter++;
      }
      rows.add(Expanded(child: Row(children: cells)));
    }
    return rows;
  }

  String _formatMonth(DateTime month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }
}

/// Day button using TextButton for reliable tap handling on all platforms.
class _DayButton extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool hasTask;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.isToday,
    required this.hasTask,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: isToday ? colorScheme.primary : Colors.transparent,
        foregroundColor: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (hasTask)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
