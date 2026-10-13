import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/sheets/filter_sheet.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(expenseTotalsProvider);
    final grand = ref.watch(grandTotalProvider);
    final filter = ref.watch(expenseFilterProvider);
    final filterNotifier = ref.read(expenseFilterProvider.notifier);

    // Find top category
    ExpenseCategory? topCategory;
    double maxAmt = 0;
    totals.forEach((cat, amt) {
      if (amt > maxAmt) {
        maxAmt = amt;
        topCategory = cat;
      }
    });

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Header with Title & Filter Pill ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATISTICS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Expense Stats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
                _FilterPill(
                  label: filter.filterLabel,
                  onTap: () => _showFilterSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 2. Quick Mode Selector Segmented Chips ──────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF161619),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: ['All Time', 'Month', 'Year'].map((mode) {
                  final active = filter.mode == mode;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => filterNotifier.setFilterMode(mode),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.transparent,
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            mode,
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.45),
                              fontSize: 12.5,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── 3. Quick Month / Year Stepper Bar (if not All Time) ─────
            if (filter.mode != 'All Time') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF131315),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                      onPressed: () {
                        if (filter.mode == 'Month') {
                          if (filter.selectedMonth == 1) {
                            filterNotifier.setSelectedYear(filter.selectedYear - 1);
                            filterNotifier.setSelectedMonth(12);
                          } else {
                            filterNotifier.setSelectedMonth(filter.selectedMonth - 1);
                          }
                        } else if (filter.mode == 'Year') {
                          filterNotifier.setSelectedYear(filter.selectedYear - 1);
                        }
                      },
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterSheet(context),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: Colors.white60,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            filter.filterLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                      onPressed: () {
                        if (filter.mode == 'Month') {
                          if (filter.selectedMonth == 12) {
                            filterNotifier.setSelectedYear(filter.selectedYear + 1);
                            filterNotifier.setSelectedMonth(1);
                          } else {
                            filterNotifier.setSelectedMonth(filter.selectedMonth + 1);
                          }
                        } else if (filter.mode == 'Year') {
                          filterNotifier.setSelectedYear(filter.selectedYear + 1);
                        }
                      },
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // ── 4. Total Summary Card (Apple Obsidian Glass) ────────────
            Container(
              padding: const EdgeInsets.all(20),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1B1B1E),
                    Color(0xFF101012),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Top specular bevel line
                  Positioned(
                    top: 0,
                    left: 12,
                    right: 12,
                    height: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            filter.mode == 'All Time'
                                ? 'ALL TIME TOTAL'
                                : 'TOTAL (${filter.filterLabel.toUpperCase()})',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.50),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (topCategory != null && grand > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 0.6,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    topCategory!.iconData,
                                    size: 11,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Top: ${topCategory!.label}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₹${formatCurrency(grand)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 28),

            // ── 5. Category Breakdown Heading ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category Breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${ExpenseCategory.values.length} Categories',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 6. Category Progress Cards ──────────────────────────────
            if (grand == 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131315),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 36,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No expenses in ${filter.filterLabel}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try switching the filter above to view past data.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...ExpenseCategory.values.map((cat) {
                final amt = totals[cat] ?? 0;
                final pct = grand > 0 ? amt / grand : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151518),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    width: 0.6,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    cat.iconData,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(pct * 100).toStringAsFixed(1)}% of total',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '₹${formatCurrency(amt)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Smooth Progress Track
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                            FractionallySizedBox(
                              widthFactor: pct.clamp(0.0, 1.0),
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FilterSheet(),
    );
  }
}

/// Minimalist frosted pill button for opening filter modal
class _FilterPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
