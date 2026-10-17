import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/industrial_background.dart';

class FeatureOverviewScreen extends StatefulWidget {
  const FeatureOverviewScreen({super.key});

  @override
  State<FeatureOverviewScreen> createState() => _FeatureOverviewScreenState();
}

class _FeatureOverviewScreenState extends State<FeatureOverviewScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_FeatureItem> _features = const [
    _FeatureItem(
      badge: 'SMART DETECTION',
      title: 'Automated Bank\nSMS Detection',
      description:
          'Never miss a fuel or repair spend. MotoLogg automatically inspects bank debit SMS (UPI, Card, ATM) and logs expenses in seconds.',
      icon: Icons.sms_rounded,
      highlights: [
        '⚡ 1-Tap Notification Quick-Save Actions',
        '🛡️ Smart Duplicate Transaction Shield',
        '🔄 Background Missed SMS Catch-Up Sync',
      ],
      glowColor: Color(0xFF64D2FF),
    ),
    _FeatureItem(
      badge: 'PERFORMANCE',
      title: 'Precise Mileage &\nFuel Cost Tracker',
      description:
          'Track fuel stops and odometer readings to calculate your exact fuel efficiency (km/L), trip distance, and running cost per km.',
      icon: Icons.local_gas_station_rounded,
      highlights: [
        '📊 Real-Time km/L & Running Cost per km',
        '🛣️ Trip Distance & Odometer Validation',
        '⛽ Complete Fuel Logs & Cost History',
      ],
      glowColor: Color(0xFFFF9F0A),
    ),
    _FeatureItem(
      badge: 'EXPENSE LEDGER',
      title: 'Rider-Focused\nExpense Tracking',
      description:
          'Purpose-built for motorcycle riders. Track fuel, scheduled servicing, custom modifications, gear, wash, insurance, and tolls.',
      icon: Icons.receipt_long_rounded,
      highlights: [
        '🏷️ Dedicated Bike Categories & Chips',
        '📝 Merchant, Custom Notes & Reference Tags',
        '📅 Flexible Date Selection & Quick Add',
      ],
      glowColor: Color(0xFF30D158),
    ),
    _FeatureItem(
      badge: 'ANALYTICS',
      title: 'Visual Reports &\nInteractive Calendar',
      description:
          'Gain deep visibility into your motorcycle costs with monthly category distributions, spending trends, and a day-by-day calendar view.',
      icon: Icons.calendar_month_rounded,
      highlights: [
        '📆 Day-by-Day Interactive Expense Calendar',
        '🥧 Category Percentage Breakdown',
        '📈 Monthly & Yearly Expense Trends',
      ],
      glowColor: Color(0xFFBF5AF2),
    ),
    _FeatureItem(
      badge: 'GARAGE & CLOUD',
      title: 'Multi-Bike Garage &\nReal-Time Backup',
      description:
          'Switch between your favorite motorcycles with realistic specs and photos. Your data is privately and securely backed up with Firebase Cloud.',
      icon: Icons.two_wheeler_rounded,
      highlights: [
        '🏍️ Custom Garage (Yamaha, Bajaj, Honda & More)',
        '☁️ Seamless Real-Time Firebase Sync',
        '🔒 Secure, Multi-Device Cloud Access',
      ],
      glowColor: Color(0xFFFF375F),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    HapticFeedback.mediumImpact();
    await OnboardingService.markFeaturesSeen();

    if (!mounted) return;

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.root);
    }
  }

  void _handleNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _features.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _handleComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _features.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndustrialBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Icon(
                            Icons.two_wheeler_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'MOTO LOGG',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    // Skip Button
                    TextButton(
                      onPressed: _handleComplete,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // PageView Slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _features.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    HapticFeedback.selectionClick();
                  },
                  itemBuilder: (context, index) {
                    final item = _features[index];
                    return _FeatureCard(item: item, step: index + 1, total: _features.length);
                  },
                ),
              ),

              // Bottom Indicator & Action Row
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_features.length, (index) {
                        final isSelected = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: isSelected ? 26 : 7,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons Row
                    Row(
                      children: [
                        if (_currentPage > 0) ...[
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // Main Next / Get Started Button
                        Expanded(
                          child: InkWell(
                            onTap: _handleNext,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLastPage ? 'Get Started' : 'Next Feature',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isLastPage
                                        ? Icons.check_circle_rounded
                                        : Icons.arrow_forward_rounded,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String badge;
  final String title;
  final String description;
  final IconData icon;
  final List<String> highlights;
  final Color glowColor;

  const _FeatureItem({
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
    required this.highlights,
    required this.glowColor,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;
  final int step;
  final int total;

  const _FeatureCard({
    required this.item,
    required this.step,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Glowing Icon Frame
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient Radial Glow
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: item.glowColor.withValues(alpha: 0.25),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),

                // Icon Container
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 350.ms),

          const SizedBox(height: 24),

          // Badge pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Text(
              item.badge,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
                fontSize: 10,
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 14),

          // Title
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 12),

          // Description
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Highlights Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, size: 16, color: item.glowColor),
                    const SizedBox(width: 8),
                    Text(
                      'KEY CAPABILITIES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textDim,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...item.highlights.map(
                  (text) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.06, end: 0),
        ],
      ),
    );
  }
}
