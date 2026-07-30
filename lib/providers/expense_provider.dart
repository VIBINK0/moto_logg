import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/firestore_service.dart';

class ExpenseFilterState {
  final String mode; // 'All Time' | 'Month' | 'Year'
  final int selectedMonth;
  final int selectedYear;

  ExpenseFilterState({
    required this.mode,
    required this.selectedMonth,
    required this.selectedYear,
  });

  factory ExpenseFilterState.initial() => ExpenseFilterState(
        mode: 'Month',
        selectedMonth: DateTime.now().month,
        selectedYear: DateTime.now().year,
      );

  ExpenseFilterState copyWith({
    String? mode,
    int? selectedMonth,
    int? selectedYear,
  }) {
    return ExpenseFilterState(
      mode: mode ?? this.mode,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }

  String get filterLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    switch (mode) {
      case 'Month':
        return '${months[selectedMonth - 1]} $selectedYear';
      case 'Year':
        return '$selectedYear';
      default:
        return 'All Time';
    }
  }
}

class ExpenseFilterNotifier extends Notifier<ExpenseFilterState> {
  @override
  ExpenseFilterState build() => ExpenseFilterState.initial();

  void setFilterMode(String mode) => state = state.copyWith(mode: mode);
  
  void setSelectedMonth(int month) => 
      state = state.copyWith(selectedMonth: month, mode: 'Month');

  void setSelectedYear(int year) {
    if (state.mode == 'All Time') {
      state = state.copyWith(selectedYear: year, mode: 'Year');
    } else {
      state = state.copyWith(selectedYear: year);
    }
  }
}

final expenseFilterProvider = NotifierProvider<ExpenseFilterNotifier, ExpenseFilterState>(
  ExpenseFilterNotifier.new,
);

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return FirestoreService(uid: user.uid).stream();
});

final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final allExpenses = ref.watch(expensesStreamProvider).value ?? [];
  final filter = ref.watch(expenseFilterProvider);

  switch (filter.mode) {
    case 'Month':
      return allExpenses
          .where((e) => e.date.year == filter.selectedYear && e.date.month == filter.selectedMonth)
          .toList();
    case 'Year':
      return allExpenses.where((e) => e.date.year == filter.selectedYear).toList();
    default:
      return allExpenses;
  }
});

final expenseTotalsProvider = Provider<Map<ExpenseCategory, double>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  final m = {for (var c in ExpenseCategory.values) c: 0.0};
  for (final e in expenses) {
    m[e.category] = (m[e.category] ?? 0) + e.amount;
  }
  return m;
});

final grandTotalProvider = Provider<double>((ref) {
  return ref.watch(filteredExpensesProvider).fold(0, (s, e) => s + e.amount);
});

// For mutations, we can use a class or just providers
final expenseServiceProvider = Provider((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return user != null ? FirestoreService(uid: user.uid) : null;
});
