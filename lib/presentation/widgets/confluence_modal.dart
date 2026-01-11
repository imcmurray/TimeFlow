import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';
import 'package:timeflow/presentation/widgets/task_card.dart';
import 'package:timeflow/presentation/widgets/water_ripple_painter.dart';

/// A modal that shows expanded view of merged/overlapping tasks.
///
/// Tasks "diverge" from the merged state with a smooth animation,
/// showing each task as a full TaskCard. Users can interact with
/// individual tasks from this modal.
class ConfluenceModal extends StatefulWidget {
  /// The list of overlapping tasks.
  final List<Task> tasks;

  /// Whether to use 24-hour time format.
  final bool use24HourFormat;

  /// Reminder states for each task, keyed by task ID.
  final Map<String, ReminderState> reminderStates;

  /// Reminder times for each task, keyed by task ID.
  final Map<String, DateTime> reminderTimes;

  /// Callback when a task is tapped for editing.
  final Function(Task)? onTaskTap;

  /// Callback when a task is swiped to complete.
  final Function(Task)? onTaskComplete;

  /// Callback when a task is swiped to delete.
  final Function(Task)? onTaskDelete;

  /// Callback when a reminder is acknowledged.
  final Function(Task)? onReminderAcknowledged;

  /// Callback when an acknowledged reminder is rescheduled.
  final Function(Task)? onReminderRescheduled;

  const ConfluenceModal({
    super.key,
    required this.tasks,
    this.use24HourFormat = false,
    this.reminderStates = const {},
    this.reminderTimes = const {},
    this.onTaskTap,
    this.onTaskComplete,
    this.onTaskDelete,
    this.onReminderAcknowledged,
    this.onReminderRescheduled,
  });

  @override
  State<ConfluenceModal> createState() => _ConfluenceModalState();
}

class _ConfluenceModalState extends State<ConfluenceModal>
    with TickerProviderStateMixin {
  late AnimationController _divergeController;
  late AnimationController _rippleController;
  late List<Animation<double>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();

    // Diverge animation for cards fanning out
    _divergeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Background ripple animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Create staggered animations for each task
    _createAnimations();

    // Start the diverge animation
    _divergeController.forward();
  }

  void _createAnimations() {
    final count = widget.tasks.length;
    _slideAnimations = [];
    _fadeAnimations = [];

    for (int i = 0; i < count; i++) {
      // Stagger each card's animation
      final startInterval = i / (count + 1);
      final endInterval = (i + 2) / (count + 1);

      _slideAnimations.add(
        Tween<double>(begin: 50.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _divergeController,
            curve: Interval(
              startInterval.clamp(0.0, 1.0),
              endInterval.clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _divergeController,
            curve: Interval(
              startInterval.clamp(0.0, 1.0),
              (endInterval - 0.1).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _divergeController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    HapticFeedback.lightImpact();
    await _divergeController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort tasks: important first, then by start time
    final sortedTasks = List<Task>.from(widget.tasks)
      ..sort((a, b) {
        if (a.isImportant && !b.isImportant) return -1;
        if (!a.isImportant && b.isImportant) return 1;
        return a.startTime.compareTo(b.startTime);
      });

    // Calculate the time span for header
    final earliestStart = widget.tasks
        .map((t) => t.startTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latestEnd = widget.tasks
        .map((t) => t.endTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return GestureDetector(
      onTap: _close,
      child: AnimatedBuilder(
        animation: _divergeController,
        builder: (context, child) {
          return Container(
            color: Colors.black.withValues(
              alpha: 0.5 * _divergeController.value,
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Background ripple effect
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WaterRipplePainter(
                      animationValue: _rippleController.value,
                      color: isDark ? Colors.white : AppColors.primaryBlue,
                      rippleCount: 5,
                    ),
                  );
                },
              ),
            ),

            // Modal content
            SafeArea(
              child: Column(
                children: [
                  // Header with time span and close button
                  _buildHeader(context, earliestStart, latestEnd),

                  // Task cards
                  Expanded(
                    child: GestureDetector(
                      onTap: () {}, // Prevent closing when tapping cards area
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedTasks.length,
                        itemBuilder: (context, index) {
                          return _buildAnimatedTaskCard(
                            context,
                            sortedTasks[index],
                            index,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DateTime earliestStart,
    DateTime latestEnd,
  ) {
    final startStr = _formatTime(earliestStart);
    final endStr = _formatTime(latestEnd);

    return AnimatedBuilder(
      animation: _fadeAnimations.isNotEmpty
          ? _fadeAnimations.first
          : _divergeController,
      builder: (context, child) {
        return Opacity(
          opacity: _divergeController.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Time span
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.merge_type,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$startStr - $endStr',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.tasks.length} tasks',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Close button
            Material(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _close,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTaskCard(BuildContext context, Task task, int index) {
    final slideAnimation = index < _slideAnimations.length
        ? _slideAnimations[index]
        : _slideAnimations.last;
    final fadeAnimation = index < _fadeAnimations.length
        ? _fadeAnimations[index]
        : _fadeAnimations.last;

    return AnimatedBuilder(
      animation: _divergeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, slideAnimation.value),
          child: Opacity(
            opacity: fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TaskCard(
          task: task,
          use24HourFormat: widget.use24HourFormat,
          reminderState: widget.reminderStates[task.id],
          reminderTime: widget.reminderTimes[task.id],
          onTap: () {
            widget.onTaskTap?.call(task);
          },
          onComplete: () {
            widget.onTaskComplete?.call(task);
          },
          onDelete: () {
            widget.onTaskDelete?.call(task);
          },
          onReminderAcknowledged: () {
            widget.onReminderAcknowledged?.call(task);
          },
          onReminderRescheduled: () {
            widget.onReminderRescheduled?.call(task);
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    if (widget.use24HourFormat) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Shows the confluence modal as a full-screen overlay.
Future<void> showConfluenceModal({
  required BuildContext context,
  required List<Task> tasks,
  bool use24HourFormat = false,
  Map<String, ReminderState> reminderStates = const {},
  Map<String, DateTime> reminderTimes = const {},
  Function(Task)? onTaskTap,
  Function(Task)? onTaskComplete,
  Function(Task)? onTaskDelete,
  Function(Task)? onReminderAcknowledged,
  Function(Task)? onReminderRescheduled,
}) {
  HapticFeedback.mediumImpact();

  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ConfluenceModal(
          tasks: tasks,
          use24HourFormat: use24HourFormat,
          reminderStates: reminderStates,
          reminderTimes: reminderTimes,
          onTaskTap: onTaskTap,
          onTaskComplete: onTaskComplete,
          onTaskDelete: onTaskDelete,
          onReminderAcknowledged: onReminderAcknowledged,
          onReminderRescheduled: onReminderRescheduled,
        );
      },
    ),
  );
}
