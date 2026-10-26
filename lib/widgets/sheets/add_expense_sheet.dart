import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/bike_model.dart';
import '../../models/expense_model.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';
import '../common/primary_button.dart';

// Form State for AddExpense
class AddExpenseFormState {
  final ExpenseCategory category;
  final DateTime selectedDate;
  final String? selectedBikeName;
  final bool isLoading;
  final String? errorMessage;

  AddExpenseFormState({
    required this.category,
    required this.selectedDate,
    this.selectedBikeName,
    this.isLoading = false,
    this.errorMessage,
  });

  AddExpenseFormState copyWith({
    ExpenseCategory? category,
    DateTime? selectedDate,
    String? selectedBikeName,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AddExpenseFormState(
      category: category ?? this.category,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedBikeName: selectedBikeName ?? this.selectedBikeName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AddExpenseFormNotifier extends Notifier<AddExpenseFormState> {
  @override
  AddExpenseFormState build() {
    final currentBike = ref.read(bikeProvider).selectedBike;
    return AddExpenseFormState(
      category: ExpenseCategory.fuel,
      selectedDate: DateTime.now(),
      selectedBikeName: currentBike?.name ?? BikeModel.defaultBike.name,
    );
  }

  void setCategory(ExpenseCategory category) => state = state.copyWith(category: category);
  void setDate(DateTime date) => state = state.copyWith(selectedDate: date);
  void setBikeName(String bikeName) => state = state.copyWith(selectedBikeName: bikeName);
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setError(String? error) => state = state.copyWith(errorMessage: error);
  void reset() => state = AddExpenseFormState(
        category: ExpenseCategory.fuel,
        selectedDate: DateTime.now(),
        selectedBikeName: ref.read(bikeProvider).selectedBike?.name ?? BikeModel.defaultBike.name,
        isLoading: false,
      );
}

final addExpenseFormProvider =
    NotifierProvider.autoDispose<AddExpenseFormNotifier, AddExpenseFormState>(
        AddExpenseFormNotifier.new);

class AddExpenseSheet extends ConsumerWidget {
  const AddExpenseSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final formState = ref.watch(addExpenseFormProvider);
    final formNotifier = ref.read(addExpenseFormProvider.notifier);
    final bikeState = ref.watch(bikeProvider);

    final amountController = ref.watch(_amountControllerProvider);
    final noteController = ref.watch(_noteControllerProvider);

    final effectiveBikeName = formState.selectedBikeName ??
        bikeState.selectedBike?.name ??
        BikeModel.defaultBike.name;

    Future<void> save() async {
      final amount = double.tryParse(amountController.text.trim());
      if (amount == null || amount <= 0) {
        formNotifier.setError('Enter a valid amount');
        return;
      }
      formNotifier.setLoading(true);
      formNotifier.setError(null);
      
      try {
        final service = ref.read(expenseServiceProvider);
        if (service == null) {
          formNotifier.setError('Please sign in to add expenses');
          return;
        }

        await service.add(Expense(
          id: '',
          category: formState.category,
          amount: amount,
          date: formState.selectedDate,
          notes: noteController.text.trim(),
          bikeName: effectiveBikeName,
        ));

        // Also sync active bike with the expense's bike
        final matchedBike = BikeModel.findByName(effectiveBikeName);
        if (matchedBike != null) {
          ref.read(bikeProvider.notifier).selectBike(matchedBike);
        }

        amountController.clear();
        noteController.clear();
        formNotifier.setLoading(false);

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        formNotifier.setError('Error saving expense: $e');
      } finally {
        formNotifier.setLoading(false);
      }
    }

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
            const SizedBox(height: 24),
            Text(
              'New Expense',
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
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
                    final isSelected = b.name.toLowerCase() == effectiveBikeName.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(b.name),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) formNotifier.setBikeName(b.name);
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
                  final isSelected = c == formState.category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.label),
                      selected: isSelected,
                      onSelected: (val) => formNotifier.setCategory(c),
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
              controller: amountController,
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
                  initialDate: formState.selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) formNotifier.setDate(picked);
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
                      '${formState.selectedDate.day}/${formState.selectedDate.month}/${formState.selectedDate.year}',
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
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'What was this for?',
              ),
            ),
            
            const SizedBox(height: 28),
            if (formState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(formState.errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
              ).animate().shake(),

            PrimaryButton(
              label: 'Add Expense',
              isLoading: formState.isLoading,
              onPressed: save,
            ),
          ],
        ),
      ),
    );
  }
}

final _amountControllerProvider = Provider.autoDispose((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});
final _noteControllerProvider = Provider.autoDispose((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

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
