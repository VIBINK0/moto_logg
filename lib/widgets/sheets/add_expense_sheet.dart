import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../common/primary_button.dart';

// Form State for AddExpense
class AddExpenseFormState {
  final ExpenseCategory category;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;

  AddExpenseFormState({
    required this.category,
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
  });

  AddExpenseFormState copyWith({
    ExpenseCategory? category,
    DateTime? selectedDate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AddExpenseFormState(
      category: category ?? this.category,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AddExpenseFormNotifier extends AutoDisposeNotifier<AddExpenseFormState> {
  @override
  AddExpenseFormState build() => AddExpenseFormState(
        category: ExpenseCategory.fuel,
        selectedDate: DateTime.now(),
      );

  void setCategory(ExpenseCategory category) => state = state.copyWith(category: category);
  void setDate(DateTime date) => state = state.copyWith(selectedDate: date);
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setError(String? error) => state = state.copyWith(errorMessage: error);
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

    // We still use controllers for text input as it's standard and more efficient
    // but the rest of the UI state is in Riverpod.
    final amountController = ref.watch(_amountControllerProvider);
    final noteController = ref.watch(_noteControllerProvider);

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
        if (service != null) {
          await service.add(Expense(
            id: '',
            category: formState.category,
            amount: amount,
            date: formState.selectedDate,
            notes: noteController.text.trim(),
          ));
          if (context.mounted) Navigator.pop(context);
        }
      } catch (e) {
        formNotifier.setError('Error saving expense');
        formNotifier.setLoading(false);
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'New Expense',
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 24),
          
          _Label('CATEGORY'),
          const SizedBox(height: 12),
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
          
          const SizedBox(height: 24),
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
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
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
          
          const SizedBox(height: 32),
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
    );
  }
}

// Internal providers for controllers to keep the UI clean
final _amountControllerProvider = Provider.autoDispose((ref) => TextEditingController());
final _noteControllerProvider = Provider.autoDispose((ref) => TextEditingController());

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}
