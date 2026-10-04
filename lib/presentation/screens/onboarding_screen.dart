import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/screens/onboarding/onboarding_slide.dart';
import 'package:timeflow/presentation/screens/onboarding/onboarding_slides.dart';
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
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  WelcomeSlide(isDark: isDark),
                  NowLineSlide(isDark: isDark),
                  TasksSlide(isDark: isDark),
                  ConfluentMergeSlide(isDark: isDark),
                  GetStartedSlide(isDark: isDark),
                ],
              ),
            ),
            OnboardingNavigation(
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
