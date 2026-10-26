import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bike_model.dart';
import '../models/expense_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'bike_provider.dart';

class ExpenseFilterState {
  final String mode; // 'All Time' | 'Month' | 'Year'
  final int selectedMonth;
  final int selectedYear;
  final String? selectedBikeName; // null means follow selectedBike, 'All' means all machines

  ExpenseFilterState({
    required this.mode,
    required this.selectedMonth,
    required this.selectedYear,
    this.selectedBikeName,
  });

  factory ExpenseFilterState.initial() => ExpenseFilterState(
        mode: 'Month',
        selectedMonth: DateTime.now().month,
        selectedYear: DateTime.now().year,
        selectedBikeName: null,
      );

  ExpenseFilterState copyWith({
    String? mode,
    int? selectedMonth,
    int? selectedYear,
    String? Function()? selectedBikeName,
  }) {
    return ExpenseFilterState(
      mode: mode ?? this.mode,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedBikeName: selectedBikeName != null
          ? selectedBikeName()
          : this.selectedBikeName,
    );
  }

  String get filterLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr = switch (mode) {
      'Month' => '${months[selectedMonth - 1]} $selectedYear',
      'Year' => '$selectedYear',
      _ => 'All Time',
    };
    if (selectedBikeName != null && selectedBikeName!.isNotEmpty && selectedBikeName != 'All') {
      return '$selectedBikeName • $dateStr';
    } else if (selectedBikeName == 'All') {
      return 'All Machines • $dateStr';
    }
    return dateStr;
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

  void setSelectedBikeName(String? bikeName) {
    state = state.copyWith(selectedBikeName: () => bikeName);
  }

  void reset() => state = ExpenseFilterState.initial();
}

final expenseFilterProvider = NotifierProvider<ExpenseFilterNotifier, ExpenseFilterState>(
  ExpenseFilterNotifier.new,
);

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return FirestoreService(uid: user.uid).stream();
});

/// Indicates whether there are existing expenses with no bikeName assigned.
final hasLegacyExpensesProvider = Provider<bool>((ref) {
  final expenses = ref.watch(expensesStreamProvider).value ?? [];
  return expenses.any((e) => e.bikeName == null || e.bikeName!.trim().isEmpty);
});

/// Returns the count of legacy expenses that have no bikeName.
final legacyExpensesCountProvider = Provider<int>((ref) {
  final expenses = ref.watch(expensesStreamProvider).value ?? [];
  return expenses.where((e) => e.bikeName == null || e.bikeName!.trim().isEmpty).length;
});

/// Returns all distinct bike names found in the user's expenses.
final distinctExpenseBikesProvider = Provider<List<String>>((ref) {
  final expenses = ref.watch(expensesStreamProvider).value ?? [];
  final set = <String>{};
  for (final e in expenses) {
    if (e.bikeName != null && e.bikeName!.trim().isNotEmpty) {
      set.add(e.bikeName!.trim());
    }
  }
  return set.toList();
});

/// Returns the list of bikes owned by the current user.
/// Scoped exclusively to the user's garage configuration stored in Firestore and local storage.
final selectableBikesProvider = Provider<List<BikeModel>>((ref) {
  final bikeState = ref.watch(bikeProvider);
  final ownedNames = bikeState.ownedBikeNames;

  if (ownedNames.isNotEmpty) {
    final result = <BikeModel>[];
    for (final name in ownedNames) {
      final matched = BikeModel.findByName(name);
      result.add(
        matched ??
            BikeModel(
              id: name.toLowerCase().replaceAll(' ', '-'),
              name: name,
              imageUrl: 'asset/ns.png',
              tagline: 'My Machine',
              engineCC: 200,
              horsepower: 20,
              brandName: 'Custom',
            ),
      );
    }
    return result;
  }

  // Fallback if owned list is not yet loaded: active selected bike or default
  if (bikeState.selectedBike != null) {
    return [bikeState.selectedBike!];
  }
  return [BikeModel.defaultBike];
});

/// Returns a map of total spent on each bike (by bike name).
final bikeExpenseTotalsProvider = Provider<Map<String, double>>((ref) {
  final all = ref.watch(expensesStreamProvider).value ?? [];
  final map = <String, double>{};
  for (final e in all) {
    if (e.bikeName != null && e.bikeName!.trim().isNotEmpty) {
      final key = e.bikeName!.trim();
      map[key] = (map[key] ?? 0) + e.amount;
    }
  }
  return map;
});

/// Expenses filtered by the selected bike (or all if 'All' is selected).
final expensesForSelectedBikeProvider = Provider<List<Expense>>((ref) {
  final allExpenses = ref.watch(expensesStreamProvider).value ?? [];
  final filter = ref.watch(expenseFilterProvider);
  final selectedBike = ref.watch(bikeProvider).selectedBike;

  final targetBike = filter.selectedBikeName ?? selectedBike?.name;
  if (targetBike == null || targetBike.isEmpty || targetBike == 'All') {
    return allExpenses;
  }

  return allExpenses.where((e) {
    if (e.bikeName == null || e.bikeName!.trim().isEmpty) return false;
    return e.bikeName!.trim().toLowerCase() == targetBike.trim().toLowerCase();
  }).toList();
});

/// Fully filtered expenses considering both Bike Selection and Date Range (Month/Year/All Time).
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final allExpenses = ref.watch(expensesStreamProvider).value ?? [];
  final filter = ref.watch(expenseFilterProvider);
  final selectedBike = ref.watch(bikeProvider).selectedBike;

  var list = allExpenses;

  // Filter by selected bike
  final targetBike = filter.selectedBikeName ?? selectedBike?.name;
  if (targetBike != null && targetBike.isNotEmpty && targetBike != 'All') {
    list = list.where((e) {
      if (e.bikeName == null || e.bikeName!.trim().isEmpty) return false;
      return e.bikeName!.trim().toLowerCase() == targetBike.trim().toLowerCase();
    }).toList();
  }

  switch (filter.mode) {
    case 'Month':
      return list
          .where((e) => e.date.year == filter.selectedYear && e.date.month == filter.selectedMonth)
          .toList();
    case 'Year':
      return list.where((e) => e.date.year == filter.selectedYear).toList();
    default:
      return list;
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
final expenseServiceProvider = Provider<FirestoreService?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null ? FirestoreService(uid: user.uid) : null;
});

