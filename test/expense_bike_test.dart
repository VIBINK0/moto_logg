import 'package:flutter_test/flutter_test.dart';
import 'package:moto_logg/models/bike_model.dart';
import 'package:moto_logg/models/detected_transaction_model.dart';
import 'package:moto_logg/models/expense_model.dart';
import 'package:moto_logg/models/mileage_model.dart';
import 'package:moto_logg/providers/bike_provider.dart';

void main() {
  group('Expense Bike Integration', () {
    test('toMap and copyWith properly handle bikeName', () {
      final now = DateTime.now();
      final expense = Expense(
        id: 'exp_1',
        amount: 250.0,
        category: ExpenseCategory.fuel,
        date: now,
        notes: 'Shell V-Power',
        bikeName: 'NS 200',
      );

      final map = expense.toMap();
      expect(map['bikeName'], 'NS 200');
      expect(map['amount'], 250.0);
      expect(map['category'], 'fuel');

      // Test copyWith
      final updated = expense.copyWith(bikeName: 'MT-15');
      expect(updated.bikeName, 'MT-15');
      expect(updated.amount, 250.0);
    });

    test('DetectedTransaction toExpense passes bikeName', () {
      final tx = DetectedTransaction(
        amount: 450.0,
        merchant: 'HPCL FUEL',
        transactionDate: DateTime(2026, 10, 26),
      );

      final expense = tx.toExpense(
        category: ExpenseCategory.fuel,
        bikeName: 'Unicorn',
      );

      expect(expense.bikeName, 'Unicorn');
      expect(expense.amount, 450.0);
      expect(expense.category, ExpenseCategory.fuel);
    });

    test('BikeModel findByName resolves preset bikes and returns null for unknown', () {
      final ns = BikeModel.findByName('NS 200');
      expect(ns, isNotNull);
      expect(ns?.name, 'NS 200');

      final yamaha = BikeModel.findByName('Yamaha MT-15');
      expect(yamaha, isNotNull);
      expect(yamaha?.name, 'MT-15');

      final unknown = BikeModel.findByName('Custom Chopper 500');
      expect(unknown, isNull);

      final nullLookup = BikeModel.findByName(null);
      expect(nullLookup, isNull);
    });

    test('MileageRecord serializes and deserializes bikeName', () {
      final now = DateTime(2026, 10, 26, 12, 0);
      final record = MileageRecord(
        id: 'rec_1',
        odometerReading: 12500.0,
        fuelLiters: 10.5,
        pricePerLiter: 102.5,
        date: now,
        bikeName: 'NS 200',
      );

      final json = record.toJson();
      expect(json['bikeName'], 'NS 200');
      expect(json['odometerReading'], 12500.0);

      final parsed = MileageRecord.fromJson(json);
      expect(parsed.bikeName, 'NS 200');
      expect(parsed.odometerReading, 12500.0);
      expect(parsed.totalCost, 10.5 * 102.5);
    });

    test('BikeState hasMultipleBikes evaluates correctly for single and multi-bike fleets', () {
      final singleBikeState = BikeState(
        selectedBike: BikeModel.defaultBike,
        ownedBikeNames: ['Kawasaki Ninja 300'],
      );
      expect(singleBikeState.hasMultipleBikes, isFalse);

      final multiBikeState = BikeState(
        selectedBike: BikeModel.defaultBike,
        ownedBikeNames: ['Kawasaki Ninja 300', 'Royal Enfield Continental GT 650'],
      );
      expect(multiBikeState.hasMultipleBikes, isTrue);

      final emptyBikeState = BikeState();
      expect(emptyBikeState.hasMultipleBikes, isFalse);
    });
  });
}
