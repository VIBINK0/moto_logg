import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/mileage_provider.dart';
import '../../widgets/sheets/add_mileage_sheet.dart';

class MileageTrackerScreen extends StatelessWidget {
  const MileageTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          'Mileage Tracker',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddMileageSheet(context),
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _AverageMileageCard(),
          Expanded(child: const _MileageHistoryList()),
        ],
      ),
    );
  }

  void _showAddMileageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddMileageSheet(),
    );
  }
}

class _AverageMileageCard extends StatelessWidget {
  const _AverageMileageCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MileageProvider>();
    final records = provider.records;
    
    // Only show average if there are more than 2 records (at least 2 comparisons)
    if (records.length <= 2) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Average',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.averageMileage.toStringAsFixed(2)} km/L',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.speed_rounded, color: AppColors.textPrimary, size: 32),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.border, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'TOTAL SPENT', value: '₹${provider.totalSpent.toInt()}'),
              _StatItem(label: 'AVG COST/KM', value: '₹${provider.averageCostPerKm.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MileageHistoryList extends StatelessWidget {
  const _MileageHistoryList();

  Future<bool?> _showFunnyConfirmDialog(BuildContext context) async {
    final funnyMessages = [
      "This record knows too much. Terminate?",
      "Deleting this won't lower fuel prices. Unfortunately.",
      "Are you sure? This data was finally getting comfortable here.",
      "Wait! That record has a black belt in Karate. Still delete?",
      "Warning: Deleting this might cause a slight glitch in the matrix.",
      "Are you breaking up with this record? It's not you, it's the data.",
      "Once it's gone, it's gone. Like your bike's warranty.",
      "This data had a family! You monster!",
      "Are you sure? This record was the chosen one!",
    ];
    final message = funnyMessages[Random().nextInt(funnyMessages.length)];

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 12),
            Text("Wait a sec!", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("SAVE IT", style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DESTROY", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MileageProvider>();
    final comparisons = provider.comparisons;

    if (comparisons.isEmpty) {
      return const Center(
        child: Text(
          'No records yet. Tap + to add.',
          style: TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: comparisons.length,
      itemBuilder: (context, index) {
        final comp = comparisons[index];
        final record = comp.current;
        final bool hasPrevious = comp.previous != null;

        return Dismissible(
          key: Key(record.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) => _showFunnyConfirmDialog(context),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          ),
          onDismissed: (_) {
            provider.deleteRecord(record.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Poof! It vanished into thin air.',style: TextStyle(color: Colors.white)),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.cardBg,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${record.date.day}/${record.date.month}/${record.date.year}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                    if (hasPrevious)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${comp.mileage.toStringAsFixed(1)} km/L',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoItem(label: 'ODOMETER', value: '${record.odometerReading.toInt()} km'),
                    _InfoItem(label: 'FUEL', value: '${record.fuelLiters} L'),
                    _InfoItem(label: 'PRICE/L', value: '₹${record.pricePerLiter}'),
                  ],
                ),
                if (hasPrevious) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppColors.border, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoItem(label: 'TRIP', value: '${comp.distanceTraveled.toInt()} km'),
                      _InfoItem(label: 'COST/KM', value: '₹${comp.pricePerKm.toStringAsFixed(2)}'),
                      _InfoItem(label: 'TOTAL', value: '₹${record.totalCost.toInt()}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
