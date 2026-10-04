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
          'TimeFlow shows your day as a river. Tasks drift toward the present and flow past it, so you always see what\'s now, what\'s next, and what\'s behind you.',
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
          'The blue line is the present moment. The timeline moves on its own as time passes, so the present stays in view. Long-press the line to move it up or down the screen.',
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
      title: 'Plan your day',
      tagline: 'Tap + or long-press the timeline.',
      description:
          'Give tasks a time, a gentle reminder, a repeat pattern, notes or a photo. Swipe a task right when it\'s done, left to delete it.',
    );
  }
}

/// Sharing explanation slide.
class ShareSlide extends StatelessWidget {
  const ShareSlide({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return OnboardingSlide(
      isDark: isDark,
      icon: Icon(Icons.ios_share, size: 80, color: AppColors.primaryBlue),
      title: 'Hand over your day',
      tagline: 'One link, no sign-up.',
      description:
          'Share a day or a week with a pet sitter, caregiver or family member. '
          'They open the link in any browser and see the same live river. '
          'Your tasks stay on your device; the schedule travels inside the link.',
    );
  }
}

/// Final get-started slide.
class GetStartedSlide extends StatelessWidget {
  const GetStartedSlide({super.key, required this.isDark, this.onSampleDay});
  final bool isDark;
  final VoidCallback? onSampleDay;

  @override
  Widget build(BuildContext context) {
    return OnboardingSlide(
      isDark: isDark,
      icon: Icon(
        Icons.check_circle_outline,
        size: 80,
        color: AppColors.secondaryGreen,
      ),
      title: "You're ready",
      tagline: 'Let time flow.',
      description:
          'Start with an empty river, or add a sample day to see how it works. '
          'Sample tasks can be deleted like any other.',
      footer: onSampleDay == null
          ? null
          : OutlinedButton.icon(
              onPressed: onSampleDay,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Start with a sample day'),
            ),
    );
  }
}
