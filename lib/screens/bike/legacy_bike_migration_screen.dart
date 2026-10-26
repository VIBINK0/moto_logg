import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/bike_model.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/industrial_background.dart';

class LegacyBikeMigrationScreen extends ConsumerStatefulWidget {
  const LegacyBikeMigrationScreen({super.key});

  @override
  ConsumerState<LegacyBikeMigrationScreen> createState() =>
      _LegacyBikeMigrationScreenState();
}

class _LegacyBikeMigrationScreenState
    extends ConsumerState<LegacyBikeMigrationScreen> {
  int _selectedIndex = 0;
  bool _isUpdating = false;
  String? _errorMessage;

  Future<void> _updateRecords(int legacyCount) async {
    if (_isUpdating) return;

    final bikes = BikeModel.availableBikes;
    final selectedBike = bikes[_selectedIndex];

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });
    HapticFeedback.heavyImpact();

    try {
      final service = ref.read(expenseServiceProvider);
      if (service == null) {
        setState(() {
          _errorMessage = 'User session expired. Please re-login.';
          _isUpdating = false;
        });
        return;
      }

      // Update all previous expenses without a bike name
      final updatedCount =
          await service.assignBikeToLegacyExpenses(selectedBike.name);

      // Select this bike as the user's active machine
      await ref.read(bikeProvider.notifier).selectBike(selectedBike);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully assigned $updatedCount records to ${selectedBike.name}! 🏍️',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF1B1B1E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update records: $e';
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final legacyCount = ref.watch(legacyExpensesCountProvider);
    final bikes = BikeModel.availableBikes;
    final selectedBike = bikes[_selectedIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndustrialBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orangeAccent.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_fix_high_rounded,
                            color: Colors.orangeAccent,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'ONE-TIME SETUP',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ASSIGN YOUR\nMACHINE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      legacyCount > 0
                          ? 'Found $legacyCount previous records without a bike. Select which bike they belong to so we can link them properly.'
                          : 'Select your machine to link with your garage records.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bike options list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: bikes.length,
                  itemBuilder: (context, index) {
                    final bike = bikes[index];
                    final isSelected = index == _selectedIndex;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1B1B1E)
                              : const Color(0xFF101012),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00FF88)
                                : Colors.white.withValues(alpha: 0.12),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00FF88)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Thumbnail
                            Container(
                              width: 64,
                              height: 64,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                bike.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.two_wheeler_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bike.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${bike.brandName} • ${bike.engineCC}cc • ${bike.horsepower}hp',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '"${bike.tagline}"',
                                    style: const TextStyle(
                                      color: Color(0xFF00FF88),
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Radio Indicator
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00FF88)
                                      : Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF00FF88),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Submit Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: GestureDetector(
                  onTap: _isUpdating ? null : () => _updateRecords(legacyCount),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isUpdating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.black, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  legacyCount > 0
                                      ? 'LINK $legacyCount RECORDS TO ${selectedBike.name.toUpperCase()}'
                                      : 'CONTINUE WITH ${selectedBike.name.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
