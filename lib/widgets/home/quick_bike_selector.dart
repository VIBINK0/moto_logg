import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/formatters.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';

class QuickBikeSelector extends ConsumerWidget {
  const QuickBikeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikes = ref.watch(selectableBikesProvider);
    if (bikes.length <= 1) {
      return const SizedBox.shrink();
    }

    final bikeState = ref.watch(bikeProvider);
    final filter = ref.watch(expenseFilterProvider);
    final totalsMap = ref.watch(bikeExpenseTotalsProvider);
    final allExpenses = ref.watch(expensesStreamProvider).value ?? [];
    final grandAll = allExpenses.fold<double>(0, (s, e) => s + e.amount);

    final activeBikeName = filter.selectedBikeName ?? bikeState.selectedBike?.name;
    final isAllSelected = filter.selectedBikeName == 'All';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR MACHINES',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              if (activeBikeName != null)
                Text(
                  isAllSelected ? 'All Machines Active' : '$activeBikeName Active',
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 64,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // ── All Bikes Chip ─────────────────────────
              _BikeChip(
                label: 'All Bikes',
                subtitle: '₹${formatCurrency(grandAll)}',
                isSelected: isAllSelected,
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isAllSelected
                        ? const Color(0xFF00FF88).withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.all_inclusive_rounded,
                    size: 18,
                    color: isAllSelected ? const Color(0xFF00FF88) : Colors.white70,
                  ),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(expenseFilterProvider.notifier).setSelectedBikeName('All');
                },
              ),

              // ── Individual Bike Chips ──────────────────
              ...bikes.map((bike) {
                final isSelected = !isAllSelected &&
                    activeBikeName?.toLowerCase() == bike.name.toLowerCase();
                final bikeTotal = totalsMap[bike.name] ?? 0.0;

                return _BikeChip(
                  label: bike.name,
                  subtitle: '₹${formatCurrency(bikeTotal)}',
                  isSelected: isSelected,
                  leading: Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00FF88).withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      bike.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.two_wheeler_rounded,
                        size: 20,
                        color: isSelected ? const Color(0xFF00FF88) : Colors.white60,
                      ),
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(bikeProvider.notifier).selectBike(bike);
                    ref.read(expenseFilterProvider.notifier).setSelectedBikeName(bike.name);
                  },
                );
              }),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms, curve: Curves.easeOutCubic);
  }
}

class _BikeChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final Widget leading;
  final VoidCallback onTap;

  const _BikeChip({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00FF88).withValues(alpha: 0.10)
              : const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00FF88)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF88),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF00FF88)
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
