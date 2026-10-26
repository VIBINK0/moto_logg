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
  Future<void> update(Expense e) => _col.doc(e.id).update(e.toMap());
  Future<void> delete(String id) => _col.doc(id).delete();

  /// Updates all existing expenses that don't have a bikeName assigned.
  /// If [updateAll] is true, updates every expense in the collection to [bikeName].
  Future<int> assignBikeToLegacyExpenses(String bikeName, {bool updateAll = false}) async {
    final snapshot = await _col.get();
    int count = 0;
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int batchCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final existingBike = data['bikeName'] as String? ?? data['bike'] as String?;
      if (updateAll || existingBike == null || existingBike.trim().isEmpty) {
        batch.update(doc.reference, {'bikeName': bikeName});
        count++;
        batchCount++;
        if (batchCount >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }
    return count;
  }

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

