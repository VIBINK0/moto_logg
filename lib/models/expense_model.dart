import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ExpenseCategory { fuel, service, accessories, modifications }

extension CatX on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.fuel:
        return 'Fuel';
      case ExpenseCategory.service:
        return 'Service';
      case ExpenseCategory.accessories:
        return 'Accessories';
      case ExpenseCategory.modifications:
        return 'Modifications';
    }
  }

  IconData get iconData {
    switch (this) {
      case ExpenseCategory.fuel:
        return Icons.local_gas_station_rounded;
      case ExpenseCategory.service:
        return Icons.build_circle_rounded;
      case ExpenseCategory.accessories:
        return Icons.extension_rounded;
      case ExpenseCategory.modifications:
        return Icons.construction_rounded;
    }
  }

  String get firestoreKey => name;
}

class Expense {
  final String id;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? notes;

  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.firestoreKey == (d['category'] as String),
        orElse: () => ExpenseCategory.fuel,
      ),
      amount: (d['amount'] as num).toDouble(),
      date: (d['date'] as Timestamp).toDate(),
      notes: d['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'category': category.firestoreKey,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}
