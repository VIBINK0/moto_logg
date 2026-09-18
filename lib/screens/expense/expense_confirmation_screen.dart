import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/detected_transaction_model.dart';
import '../../models/expense_model.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_transaction_service.dart';
import '../../widgets/common/primary_button.dart';

// State model for the confirmation form
class ExpenseConfirmState {
  final ExpenseCategory category;
  final String paymentMethod;
  final DateTime date;
  final bool isSaving;
  final bool isDuplicate;
  final String? errorMessage;

  const ExpenseConfirmState({
    required this.category,
    required this.paymentMethod,
    required this.date,
    this.isSaving = false,
    this.isDuplicate = false,
    this.errorMessage,
  });

  ExpenseConfirmState copyWith({
    ExpenseCategory? category,
    String? paymentMethod,
    DateTime? date,
    bool? isSaving,
    bool? isDuplicate,
    String? errorMessage,
  }) {
    return ExpenseConfirmState(
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      isSaving: isSaving ?? this.isSaving,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      errorMessage: errorMessage,
    );
  }
}

class ExpenseConfirmNotifier extends Notifier<ExpenseConfirmState> {
  @override
  ExpenseConfirmState build() {
    return ExpenseConfirmState(
      category: ExpenseCategory.fuel,
      paymentMethod: 'UPI',
      date: DateTime.now(),
    );
  }

  void initialize(DetectedTransaction tx) {
    state = ExpenseConfirmState(
      category: _inferCategory(tx.merchant),
      paymentMethod: tx.paymentMethod ?? 'UPI',
      date: tx.transactionDate,
    );
  }

  void setCategory(ExpenseCategory cat) => state = state.copyWith(category: cat);
  void setPaymentMethod(String method) => state = state.copyWith(paymentMethod: method);
  void setDate(DateTime dt) => state = state.copyWith(date: dt);
  void setSaving(bool saving) => state = state.copyWith(isSaving: saving);
  void setDuplicate(bool dup) => state = state.copyWith(isDuplicate: dup);
  void setError(String? error) => state = state.copyWith(errorMessage: error);

  static ExpenseCategory _inferCategory(String? merchant) {
    if (merchant == null) return ExpenseCategory.fuel;
    final m = merchant.toLowerCase();
    if (m.contains('petrol') || m.contains('fuel') || m.contains('hp') || m.contains('ioc') || m.contains('bpcl') || m.contains('shell')) {
      return ExpenseCategory.fuel;
    }
    if (m.contains('service') || m.contains('garage') || m.contains('repair') || m.contains('puncture') || m.contains('mechanic')) {
      return ExpenseCategory.service;
    }
    if (m.contains('parts') || m.contains('helmet') || m.contains('jacket') || m.contains('exhaust') || m.contains('gear')) {
      return ExpenseCategory.accessories;
    }
    return ExpenseCategory.fuel;
  }
}

final expenseConfirmProvider =
    NotifierProvider<ExpenseConfirmNotifier, ExpenseConfirmState>(
  ExpenseConfirmNotifier.new,
);

class ExpenseConfirmationScreen extends ConsumerStatefulWidget {
  final DetectedTransaction? transaction;

  const ExpenseConfirmationScreen({
    super.key,
    this.transaction,
  });

  @override
  ConsumerState<ExpenseConfirmationScreen> createState() => _ExpenseConfirmationScreenState();
}

class _ExpenseConfirmationScreenState extends ConsumerState<ExpenseConfirmationScreen> {
  late final TextEditingController _notesController;

  static const List<String> _paymentMethods = [
    'UPI',
    'Debit Card',
    'Credit Card',
    'Cash',
    'NetBanking',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    final initialNotes = StringBuffer();
    if (tx?.merchant != null && tx!.merchant!.isNotEmpty) {
      initialNotes.write(tx.merchant);
    }
    if (tx?.transactionId != null && tx!.transactionId!.isNotEmpty) {
      if (initialNotes.isNotEmpty) initialNotes.write(' • ');
      initialNotes.write('Ref: ${tx.transactionId}');
    }

    _notesController = TextEditingController(text: initialNotes.toString());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tx != null) {
        ref.read(expenseConfirmProvider.notifier).initialize(tx);
        _checkForDuplicates(tx);
      }
    });
  }

  Future<void> _checkForDuplicates(DetectedTransaction tx) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final service = FirestoreService(uid: user.uid);
    final isDup = await service.hasDuplicateExpense(
      transactionId: tx.transactionId,
      amount: tx.amount,
      date: tx.transactionDate,
    );
    if (mounted && isDup) {
      ref.read(expenseConfirmProvider.notifier).setDuplicate(true);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final tx = widget.transaction;
    if (tx == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save expenses.')),
      );
      return;
    }

    final formNotifier = ref.read(expenseConfirmProvider.notifier);
    final formState = ref.read(expenseConfirmProvider);

    formNotifier.setSaving(true);
    formNotifier.setError(null);

    try {
      final service = FirestoreService(uid: user.uid);
      final expense = tx.toExpense(
        category: formState.category,
        customNotes: _notesController.text.trim(),
      );

      await service.add(expense);

      // Clear the detected transaction from service state
      ref.read(smsTransactionProvider.notifier).clearTransaction();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceLight,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: 12),
                Text(
                  '₹${tx.amount.toStringAsFixed(2)} added as ${formState.category.label}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );

        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      formNotifier.setError('Failed to save expense: $e');
    } finally {
      formNotifier.setSaving(false);
    }
  }

  void _handleDismiss() {
    ref.read(smsTransactionProvider.notifier).clearTransaction();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(expenseConfirmProvider);
    final formNotifier = ref.read(expenseConfirmProvider.notifier);
    final tx = widget.transaction;

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Expense Detected'),
          backgroundColor: AppColors.bg,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 64, color: AppColors.textDim),
              const SizedBox(height: 16),
              Text(
                'No pending transaction detected.',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final formattedDate = DateFormat('dd MMM yyyy').format(formState.date);
    final formattedAmount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(tx.amount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: _handleDismiss,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AUTO-DETECTED',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense Detected',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                'Review details extracted from your bank SMS',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textDim),
              ),
              const SizedBox(height: 24),

              // Hero Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      formattedAmount,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (tx.merchant != null && tx.merchant!.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            tx.merchant!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(
                            tx.paymentMethod ?? 'Bank Transfer',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (tx.transactionId != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Ref: ${tx.transactionId}',
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

              if (formState.isDuplicate) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'An expense with this reference or amount already exists in your ledger.',
                          style: TextStyle(color: AppColors.warning, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ).animate().shake(),
              ],

              const SizedBox(height: 28),

              // Category Selector
              _SectionLabel(title: 'CATEGORY'),
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
                        onSelected: (_) => formNotifier.setCategory(c),
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        avatar: Icon(
                          c.iconData,
                          size: 16,
                          color: isSelected ? Colors.black : AppColors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected ? AppColors.accent : AppColors.border,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Method
              _SectionLabel(title: 'PAYMENT METHOD'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _paymentMethods.contains(formState.paymentMethod)
                        ? formState.paymentMethod
                        : _paymentMethods.first,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: theme.textTheme.bodyLarge,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.accent),
                    items: _paymentMethods.map((m) {
                      return DropdownMenuItem<String>(
                        value: m,
                        child: Text(m),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) formNotifier.setPaymentMethod(val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Date Picker
              _SectionLabel(title: 'DATE'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: formState.date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) formNotifier.setDate(picked);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.textDim),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Notes
              _SectionLabel(title: 'NOTES'),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Add description or tags...',
                ),
              ),

              const SizedBox(height: 32),

              if (formState.errorMessage != null) ...[
                Text(
                  formState.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
                const SizedBox(height: 16),
              ],

              // Buttons
              PrimaryButton(
                label: 'Add Expense',
                isLoading: formState.isSaving,
                onPressed: _handleSave,
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: _handleDismiss,
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppColors.textDim,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}
