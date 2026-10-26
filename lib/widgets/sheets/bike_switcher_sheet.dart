import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';

class BikeSwitcherSheet extends ConsumerWidget {
  const BikeSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const BikeSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeState = ref.watch(bikeProvider);
    final currentBike = bikeState.selectedBike;
    final bikes = ref.watch(selectableBikesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Switch Active Machine',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.bikeSettings);
                  },
                  child: const Text(
                    'Full Specs',
                    style: TextStyle(color: Color(0xFF00FF88), fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...bikes.map((bike) {
              final isSelected = currentBike?.name.toLowerCase() == bike.name.toLowerCase() ||
                  currentBike?.id == bike.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00FF88).withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00FF88)
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 0.8,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      bike.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.two_wheeler_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    bike.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '${bike.brandName} • ${bike.engineCC}cc',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF00FF88))
                      : null,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final success =
                        await ref.read(bikeProvider.notifier).selectBike(bike);
                    if (success) {
                      ref
                          .read(expenseFilterProvider.notifier)
                          .setSelectedBikeName(bike.name);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${bike.name}',
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: const Color(0xFF161618),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(milliseconds: 1500),
                        ),
                      );
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
