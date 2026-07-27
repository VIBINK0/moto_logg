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
}
