import 'expense_model.dart';

class DetectedTransaction {
  final double amount;
  final String? merchant;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime transactionDate;
  final String? rawBody;
  final String? sender;

  const DetectedTransaction({
    required this.amount,
    this.merchant,
    this.paymentMethod,
    this.transactionId,
    required this.transactionDate,
    this.rawBody,
    this.sender,
  });

  factory DetectedTransaction.fromMap(Map<dynamic, dynamic> map) {
    DateTime date;
    final dateVal = map['transactionDate'];
    if (dateVal is int) {
      date = DateTime.fromMillisecondsSinceEpoch(dateVal);
    } else if (dateVal is String) {
      date = DateTime.tryParse(dateVal) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return DetectedTransaction(
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      merchant: map['merchant'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      transactionId: map['transactionId'] as String?,
      transactionDate: date,
      rawBody: map['rawBody'] as String?,
      sender: map['sender'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'merchant': merchant,
    'paymentMethod': paymentMethod,
    'transactionId': transactionId,
    'transactionDate': transactionDate.millisecondsSinceEpoch,
    'rawBody': rawBody,
    'sender': sender,
  };

  /// Converts this detected transaction to the app's persistent [Expense] model.
  Expense toExpense({
    required ExpenseCategory category,
    String? customNotes,
  }) {
    final noteParts = <String>[];
    if (merchant != null && merchant!.isNotEmpty) {
      noteParts.add(merchant!);
    }
    if (paymentMethod != null && paymentMethod!.isNotEmpty) {
      noteParts.add('via $paymentMethod');
    }
    if (transactionId != null && transactionId!.isNotEmpty) {
      noteParts.add('[Ref: $transactionId]');
    }
    if (customNotes != null && customNotes.trim().isNotEmpty) {
      noteParts.add(customNotes.trim());
    }

    return Expense(
      id: '',
      category: category,
      amount: amount,
      date: transactionDate,
      notes: noteParts.isEmpty ? null : noteParts.join(' • '),
    );
  }
}
