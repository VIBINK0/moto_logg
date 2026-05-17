// ═══════════════════════════════════════════════════════════
//  MOTO LOGG — ExpenseProvider
//  User-scoped Firestore: users/{uid}/expenses/{docId}
//  Filter modes: 'All Time' | 'Month' | 'Year'
//  File: lib/expense_provider.dart
// ═══════════════════════════════════════════════════════════

// import 'package:MOTOLOGG/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart';

class ExpenseProvider extends ChangeNotifier {
  FirestoreService get _svc =>
      FirestoreService(uid: FirebaseAuth.instance.currentUser!.uid);

  // ── Tab ─────────────────────────────────────────────────
  int _tabIndex = 0;
  int get tabIndex => _tabIndex;
  void setTab(int i) {
    _tabIndex = i;
    notifyListeners();
  }

  // ── Filter mode ──────────────────────────────────────────
  // 'All Time' | 'Month' | 'Year'
  String _filterMode = 'Month';
  String get filterMode => _filterMode;

  int _selectedMonth = DateTime.now().month; // 1–12
  int get selectedMonth => _selectedMonth;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  void setFilterMode(String mode) {
    _filterMode = mode;
    notifyListeners();
  }

  void setSelectedMonth(int month) {
    _selectedMonth = month;
    _filterMode = 'Month';
    notifyListeners();
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    _filterMode = 'Year';
    notifyListeners();
  }

  /// Human-readable label shown on the dropdown button
  String get filterLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    switch (_filterMode) {
      case 'Month':
        return '${months[_selectedMonth - 1]} $_selectedYear';
      case 'Year':
        return '$_selectedYear';
      default:
        return 'All Time';
    }
  }

  // ── Stream ───────────────────────────────────────────────
  Stream<List<Expense>> get allExpenses => _svc.stream();

  // ── Apply filter ─────────────────────────────────────────
  List<Expense> applyFilter(List<Expense> all) {
    switch (_filterMode) {
      case 'Month':
        return all.where((e) =>
        e.date.year == _selectedYear &&
            e.date.month == _selectedMonth).toList();
      case 'Year':
        return all.where((e) => e.date.year == _selectedYear).toList();
      default: // 'All Time'
        return all;
    }
  }

  // ── Aggregates ───────────────────────────────────────────
  Map<ExpenseCategory, double> totals(List<Expense> list) {
    final m = {for (var c in ExpenseCategory.values) c: 0.0};
    for (final e in list) {
      m[e.category] = (m[e.category] ?? 0) + e.amount;
    }
    return m;
  }

  double grand(List<Expense> list) => list.fold(0, (s, e) => s + e.amount);

  // ── Mutations ────────────────────────────────────────────
  Future<void> add({
    required ExpenseCategory category,
    required double amount,
    required DateTime date,
    String? notes,
  }) =>
      _svc.add(Expense(
        id: '',
        category: category,
        amount: amount,
        date: date,
        notes: notes,
      ));

  Future<void> delete(String id) => _svc.delete(id);
}