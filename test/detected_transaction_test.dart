import 'package:flutter_test/flutter_test.dart';
import 'package:moto_logg/models/detected_transaction_model.dart';
import 'package:moto_logg/models/expense_model.dart';

void main() {
  group('DetectedTransaction', () {
    test('fromMap parses map with epoch milliseconds correctly', () {
      final now = DateTime.now();
      final map = {
        'amount': 500.0,
        'merchant': 'ABC STORE',
        'paymentMethod': 'UPI',
        'transactionId': '123456789',
        'transactionDate': now.millisecondsSinceEpoch,
        'sender': 'VM-HDFCBK',
        'rawBody': 'debited by Rs.500.00',
      };

      final tx = DetectedTransaction.fromMap(map);

      expect(tx.amount, 500.0);
      expect(tx.merchant, 'ABC STORE');
      expect(tx.paymentMethod, 'UPI');
      expect(tx.transactionId, '123456789');
      expect(tx.sender, 'VM-HDFCBK');
      expect(tx.transactionDate.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('fromMap handles ISO date string and fallback when date is missing', () {
      final map = {
        'amount': 150.5,
        'merchant': 'LOCAL CHAI',
        'transactionDate': '2026-09-17T12:00:00.000Z',
      };

      final tx = DetectedTransaction.fromMap(map);

      expect(tx.amount, 150.5);
      expect(tx.merchant, 'LOCAL CHAI');
      expect(tx.paymentMethod, isNull);
      expect(tx.transactionId, isNull);
      expect(tx.transactionDate.year, 2026);

      final emptyMap = <String, dynamic>{};
      final emptyTx = DetectedTransaction.fromMap(emptyMap);
      expect(emptyTx.amount, 0.0);
      expect(emptyTx.transactionDate, isNotNull);
    });

    test('toMap serializes all fields properly', () {
      final date = DateTime(2026, 9, 17, 14, 0);
      final tx = DetectedTransaction(
        amount: 800.0,
        merchant: 'HP PETROL PUMP',
        paymentMethod: 'UPI',
        transactionId: 'UTR112233',
        transactionDate: date,
        rawBody: 'debited Rs 800',
        sender: 'VM-SBIUPI',
      );

      final map = tx.toMap();
      expect(map['amount'], 800.0);
      expect(map['merchant'], 'HP PETROL PUMP');
      expect(map['paymentMethod'], 'UPI');
      expect(map['transactionId'], 'UTR112233');
      expect(map['transactionDate'], date.millisecondsSinceEpoch);
      expect(map['sender'], 'VM-SBIUPI');
      expect(map['rawBody'], 'debited Rs 800');
    });

    test('toExpense converts properly with custom category and notes', () {
      final tx = DetectedTransaction(
        amount: 250.0,
        merchant: 'SHELL PETROL',
        paymentMethod: 'UPI',
        transactionId: 'REF987654',
        transactionDate: DateTime(2026, 9, 17, 10, 30),
      );

      final expense = tx.toExpense(
        category: ExpenseCategory.fuel,
        customNotes: 'Morning highway refill',
      );

      expect(expense.amount, 250.0);
      expect(expense.category, ExpenseCategory.fuel);
      expect(expense.notes, contains('Morning highway refill'));
      expect(expense.notes, contains('SHELL PETROL'));
      expect(expense.notes, contains('REF987654'));
      expect(expense.date, DateTime(2026, 9, 17, 10, 30));
    });

    test('toExpense handles null merchant and missing notes cleanly', () {
      final tx = DetectedTransaction(
        amount: 100.0,
        transactionDate: DateTime(2026, 9, 17),
      );

      final expense = tx.toExpense(category: ExpenseCategory.service);
      expect(expense.amount, 100.0);
      expect(expense.category, ExpenseCategory.service);
      expect(expense.notes, isNull);
    });

    test('parses and converts IOB bank SMS transaction correctly', () {
      final map = {
        'amount': 10000.0,
        'merchant': 'IOB Payee',
        'paymentMethod': 'Bank Transfer',
        'transactionId': '7035048272486',
        'transactionDate': DateTime(2026, 9, 5).millisecondsSinceEpoch,
        'sender': 'VM-IOBBANK',
        'rawBody': 'Your a/c XXXXX99 debited for payee for Rs. 10000.00 on 2026-09-05, ref 7035048272486.If not you, report to your bank immediately-IOB.',
      };

      final tx = DetectedTransaction.fromMap(map);
      expect(tx.amount, 10000.0);
      expect(tx.merchant, 'IOB Payee');
      expect(tx.transactionId, '7035048272486');
      expect(tx.transactionDate.year, 2026);
      expect(tx.transactionDate.month, 9);
      expect(tx.transactionDate.day, 5);

      final expense = tx.toExpense(category: ExpenseCategory.service, customNotes: 'Bike service payment');
      expect(expense.amount, 10000.0);
      expect(expense.notes, contains('IOB Payee'));
      expect(expense.notes, contains('7035048272486'));
      expect(expense.notes, contains('Bike service payment'));
    });
  });
}
