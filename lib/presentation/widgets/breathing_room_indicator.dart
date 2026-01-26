import 'package:flutter/material.dart';

/// Indicator showing free time between tasks.
///
/// Celebrates open space in the schedule rather than treating
/// it as empty/unused time. Shows duration and optional
/// motivational message.
class BreathingRoomIndicator extends StatelessWidget {
  /// Duration of the free time in minutes.
  final int durationMinutes;

  /// Whether to show in compact mode (just icon + time).
  final bool compact;

  /// Callback when tapped (e.g., to add a task in this slot).
  final VoidCallback? onTap;

  const BreathingRoomIndicator({
    super.key,
    required this.durationMinutes,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Only show if gap is significant (>= 15 minutes)
    if (durationMinutes < 15) {
      return const SizedBox.shrink();
    }

    final message = _getMessage();
    final icon = _getIcon();
    final durationText = _formatDuration();

    if (compact) {
      return _buildCompact(context, icon, durationText, colorScheme, isDark);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getAccentColor(isDark).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: _getAccentColor(isDark),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    durationText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.add_circle_outline,
                size: 20,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    IconData icon,
    String durationText,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getAccentColor(isDark).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: _getAccentColor(isDark).withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  durationText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _getAccentColor(isDark).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration() {
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      if (mins == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} free';
      }
      return '${hours}h ${mins}m free';
    }
    return '$durationMinutes min free';
  }

  String _getMessage() {
    if (durationMinutes >= 120) {
      return 'A generous stretch of open time';
    } else if (durationMinutes >= 60) {
      return 'Room to breathe';
    } else if (durationMinutes >= 30) {
      return 'A moment of calm';
    } else {
      return 'Brief pause';
    }
  }

  IconData _getIcon() {
    if (durationMinutes >= 120) {
      return Icons.self_improvement;
    } else if (durationMinutes >= 60) {
      return Icons.spa;
    } else if (durationMinutes >= 30) {
      return Icons.air;
    } else {
      return Icons.pause_circle_outline;
    }
  }

  Color _getAccentColor(bool isDark) {
    // Calming teal/green colors
    if (durationMinutes >= 120) {
      return isDark ? const Color(0xFF4DB6AC) : const Color(0xFF26A69A);
    } else if (durationMinutes >= 60) {
      return isDark ? const Color(0xFF81C784) : const Color(0xFF66BB6A);
    } else if (durationMinutes >= 30) {
      return isDark ? const Color(0xFF90CAF9) : const Color(0xFF64B5F6);
    } else {
      return isDark ? const Color(0xFFB0BEC5) : const Color(0xFF90A4AE);
    }
  }
}
