import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bike_model.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';

class BikeSettingsScreen extends ConsumerWidget {
  const BikeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeState = ref.watch(bikeProvider);
    final currentBike = bikeState.selectedBike;
    final bikes = ref.watch(selectableBikesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'BIKE SETTINGS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current selection card
            if (currentBike != null) _buildCurrentBikeCard(currentBike),

            const SizedBox(height: 32),

            Text(
              'YOUR MACHINES & GARAGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 16),

            // Bike list
            ...bikes.map(
              (bike) {
                final isSelected = currentBike?.name.toLowerCase() == bike.name.toLowerCase() ||
                    currentBike?.id == bike.id;

                return _buildBikeOption(
                  context,
                  bike,
                  isSelected: isSelected,
                  onSelect: () async {
                    HapticFeedback.mediumImpact();
                    final success = await ref.read(bikeProvider.notifier).selectBike(bike);
                    if (success) {
                      ref.read(expenseFilterProvider.notifier).setSelectedBikeName(bike.name);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to ${bike.name}', style: const TextStyle(color: Colors.white)),
                            backgroundColor: const Color(0xFF161618),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(milliseconds: 1500),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBikeCard(BikeModel bike) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00FF88).withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00FF88),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CURRENTLY ACTIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00FF88).withValues(alpha: 0.9),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Image.asset(
            bike.imageUrl,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.two_wheeler_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            bike.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${bike.brandName} • ${bike.engineCC}cc • ${bike.horsepower}hp',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBikeOption(
    BuildContext context,
    BikeModel bike, {
    required bool isSelected,
    required Future<void> Function() onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!isSelected) {
              await onSelect();
            } else {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00FF88)
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? const Color(0xFF00FF88).withValues(alpha: 0.08)
                  : const Color(0xFF141416),
            ),
            child: Row(
              children: [
                // Bike thumbnail
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    bike.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.two_wheeler_rounded,
                      color: Colors.white,
                      size: 24,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bike.brandName} • ${bike.engineCC}cc',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Radio indicator / checkmark
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00FF88)
                          : Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF00FF88) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.black,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
