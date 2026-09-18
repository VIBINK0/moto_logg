import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class FirestoreService {
  final String uid;
  FirestoreService({required this.uid});

  // Per-user collection: users/{uid}/expenses
  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('expenses');

  Stream<List<Expense>> stream() => _col
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Expense.fromFirestore).toList());

  Future<void> add(Expense e) => _col.add(e.toMap());
  Future<void> delete(String id) => _col.doc(id).delete();

  /// Checks whether an expense with the given transactionId or amount+date already exists.
  Future<bool> hasDuplicateExpense({
    String? transactionId,
    required double amount,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      // Query expenses for that day (single-field range index, no composite index required)
      final query = await _col
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      for (final doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        // 1. Check reference ID in notes if present
        if (transactionId != null && transactionId.isNotEmpty) {
          final notes = data['notes'] as String? ?? '';
          if (notes.contains(transactionId)) {
            return true;
          }
        }

        // 2. Check exact amount match on the same day
        final docAmount = (data['amount'] as num?)?.toDouble();
        if (docAmount != null && (docAmount - amount).abs() < 0.01) {
          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}

