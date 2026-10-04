import 'package:flutter/material.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/presentation/screens/onboarding/onboarding_slide.dart';

/// Welcome slide introducing TimeFlow.
class WelcomeSlide extends StatelessWidget {
  const WelcomeSlide({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return OnboardingSlide(
      isDark: isDark,
      icon: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/timeflow-logo.png',
          width: 120,
          height: 120,
        ),
      ),
      title: 'Welcome to TimeFlow',
      tagline:
          'Experience time as a gentle flowing river, not a pressure cooker.',
      description:
          'TimeFlow helps you plan your day in a calm, stress-free way. No harsh alarms or urgent notifications - just a peaceful view of your schedule.',
    );
  }
}

/// NOW line explanation slide with a small demo widget.
class NowLineSlide extends StatelessWidget {
  const NowLineSlide({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return OnboardingSlide(
      isDark: isDark,
      icon: NowLineDemo(isDark: isDark),
      title: 'The NOW Line',
      tagline: 'Time flows gently past you.',
      description:
          'The glowing blue line shows the current moment. Watch as your timeline scrolls smoothly - like time flowing by naturally. The present is always in view.',
    );
  }
}

/// Mini visual demo of the NOW line used in [NowLineSlide].
class NowLineDemo extends StatelessWidget {
  const NowLineDemo({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              boxShadow: [
                BoxShadow(
                  color: AppColors.nowLineGlow,
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NOW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tasks explanation slide.
class TasksSlide extends StatelessWidget {
  const TasksSlide({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return OnboardingSlide(
      isDark: isDark,
      icon: Icon(Icons.calendar_today, size: 80, color: AppColors.primaryBlue),
      title: 'Plan Your Day',
      tagline: 'Add tasks with a simple tap.',
      description:
          'Use the + button to add tasks. Set times, add reminders, mark important items, and even attach photos. Swipe right on any task to complete it.',
    );
  }
}

/// Confluent merge explanation slide.
class ConfluentMergeSlide extends StatelessWidget {
  const ConfluentMergeSlide({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return OnboardingSlide(
      isDark: isDark,
      icon: Transform.rotate(
        angle: 3.14159265 / 2, // 90 degrees - pointing down
        child: Icon(Icons.merge_type, size: 80, color: AppColors.primaryBlue),
      ),
      title: 'Confluent Merge',
      tagline: 'Rivers converging into one.',
      description:
          'When multiple tasks overlap, they merge into a single unified card—like rivers converging into a stronger stream. Tap the merged card to see individual tasks.',
    );
  }
}

/// Final get-started slide.
class GetStartedSlide extends StatelessWidget {
  const GetStartedSlide({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return OnboardingSlide(
      isDark: isDark,
      icon: Icon(
        Icons.check_circle_outline,
        size: 80,
        color: AppColors.secondaryGreen,
      ),
      title: "You're Ready!",
      tagline: 'Start flowing with time.',
      description:
          "That's all you need to know. Tap \"Get Started\" to begin planning your day with TimeFlow.",
    );
  }
}
