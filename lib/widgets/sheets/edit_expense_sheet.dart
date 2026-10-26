import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bike_model.dart';
import '../../models/expense_model.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';
import '../common/primary_button.dart';

class EditExpenseSheet extends ConsumerStatefulWidget {
  final Expense expense;

  const EditExpenseSheet({super.key, required this.expense});

  @override
  ConsumerState<EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<EditExpenseSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  late String _selectedBikeName;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final amt = widget.expense.amount;
    final amtStr = amt % 1 == 0 ? amt.toInt().toString() : amt.toStringAsFixed(2);
    _amountController = TextEditingController(text: amtStr);
    _noteController = TextEditingController(text: widget.expense.notes ?? '');
    _selectedCategory = widget.expense.category;
    _selectedDate = widget.expense.date;
    final currentBike = ref.read(bikeProvider).selectedBike;
    _selectedBikeName = widget.expense.bikeName ?? currentBike?.name ?? BikeModel.defaultBike.name;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid amount');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(expenseServiceProvider);
      if (service == null) {
        setState(() {
          _errorMessage = 'Please sign in to update expenses';
          _isLoading = false;
        });
        return;
      }

      final updatedExpense = Expense(
        id: widget.expense.id,
        category: _selectedCategory,
        amount: amount,
        date: _selectedDate,
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        bikeName: _selectedBikeName,
      );

      await service.update(updatedExpense);

      // Also ensure active bike is aligned with the chosen bike
      final matchedBike = BikeModel.findByName(_selectedBikeName);
      if (matchedBike != null) {
        ref.read(bikeProvider.notifier).selectBike(matchedBike);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense updated successfully! 🏍️'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.cardBg,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating expense: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          "Delete this expense?",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will permanently delete this expense from your records.",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL", style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("DELETE", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(expenseServiceProvider);
      await service?.delete(widget.expense.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.cardBg,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Expense',
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
                ),
                IconButton(
                  onPressed: _deleteExpense,
                  tooltip: 'Delete Expense',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Machine / Bike Selector (Multi-bike only)
            if (ref.watch(selectableBikesProvider).length > 1) ...[
              _Label('MACHINE / BIKE'),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ref.watch(selectableBikesProvider).map((b) {
                    final isSelected = b.name.toLowerCase() == _selectedBikeName.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(b.name),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedBikeName = b.name);
                        },
                        avatar: const Icon(Icons.two_wheeler_rounded, size: 16),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            _Label('CATEGORY'),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ExpenseCategory.values.map((c) {
                  final isSelected = c == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = c),
                      avatar: Icon(
                        c.iconData,
                        size: 16,
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
            _Label('AMOUNT (₹)'),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '₹ ',
              ),
            ),

            const SizedBox(height: 20),
            _Label('DATE'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _Label('NOTES'),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'What was this for?',
              ),
            ),

            const SizedBox(height: 28),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
              ).animate().shake(),

            PrimaryButton(
              label: 'Update Expense',
              isLoading: _isLoading,
              onPressed: _updateExpense,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}
