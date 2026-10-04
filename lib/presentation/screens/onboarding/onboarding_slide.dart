import 'package:flutter/material.dart';
import 'package:cron_timeflow/core/theme/app_colors.dart';

/// Base template for an onboarding slide with icon, title, tagline, and
/// description.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
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
              color:
                  isDark ? AppColors.textLightPrimary : AppColors.textPrimary,
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
              color: isDark
                  ? AppColors.textLightSecondary
                  : AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation bar for the onboarding flow: page dots, skip and
/// next/get-started buttons.
class OnboardingNavigation extends StatelessWidget {
  const OnboardingNavigation({
    super.key,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
