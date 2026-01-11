import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/screens/timeline_screen.dart';

/// Onboarding screen shown on first app launch.
///
/// Introduces users to TimeFlow's core concepts through a 5-slide walkthrough:
/// Welcome, NOW Line, Tasks, Confluent Merge, and Get Started.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    ref.read(settingsProvider.notifier).setFirstLaunch(false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TimelineScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _WelcomeSlide(isDark: isDark),
                  _NowLineSlide(isDark: isDark),
                  _TasksSlide(isDark: isDark),
                  _ConfluentMergeSlide(isDark: isDark),
                  _GetStartedSlide(isDark: isDark),
                ],
              ),
            ),
            _OnboardingNavigation(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onSkip: _completeOnboarding,
              onNext: _nextPage,
              onDotTap: (index) => _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingNavigation extends StatelessWidget {
  const _OnboardingNavigation({
    required this.currentPage,
    required this.totalPages,
    required this.onSkip,
    required this.onNext,
    required this.onDotTap,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final void Function(int) onDotTap;

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == totalPages - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => GestureDetector(
                onTap: () => onDotTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? AppColors.primaryBlue
                        : AppColors.primaryBlueLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  isLastPage ? 'Get Started' : 'Next',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.tagline,
    required this.description,
    required this.isDark,
  });

  final Widget icon;
  final String title;
  final String tagline;
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLightPrimary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            tagline,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlide(
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
      tagline: 'Experience time as a gentle flowing river, not a pressure cooker.',
      description:
          'TimeFlow helps you plan your day in a calm, stress-free way. No harsh alarms or urgent notifications - just a peaceful view of your schedule.',
    );
  }
}

class _NowLineSlide extends StatelessWidget {
  const _NowLineSlide({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlide(
      isDark: isDark,
      icon: _NowLineDemo(isDark: isDark),
      title: 'The NOW Line',
      tagline: 'Time flows gently past you.',
      description:
          'The glowing blue line shows the current moment. Watch as your timeline scrolls smoothly - like time flowing by naturally. The present is always in view.',
    );
  }
}

class _NowLineDemo extends StatelessWidget {
  const _NowLineDemo({required this.isDark});
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

class _TasksSlide extends StatelessWidget {
  const _TasksSlide({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlide(
      isDark: isDark,
      icon: Icon(
        Icons.calendar_today,
        size: 80,
        color: AppColors.primaryBlue,
      ),
      title: 'Plan Your Day',
      tagline: 'Add tasks with a simple tap.',
      description:
          'Use the + button to add tasks. Set times, add reminders, mark important items, and even attach photos. Swipe right on any task to complete it.',
    );
  }
}

class _ConfluentMergeSlide extends StatelessWidget {
  const _ConfluentMergeSlide({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlide(
      isDark: isDark,
      icon: Icon(
        Icons.merge_type,
        size: 80,
        color: AppColors.primaryBlue,
      ),
      title: 'Confluent Merge',
      tagline: 'Rivers converging into one.',
      description:
          'When multiple tasks overlap, they merge into a single unified card—like rivers converging into a stronger stream. Tap the merged card to see individual tasks.',
    );
  }
}

class _GetStartedSlide extends StatelessWidget {
  const _GetStartedSlide({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlide(
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
