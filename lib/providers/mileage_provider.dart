import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mileage_model.dart';

class MileageProvider with ChangeNotifier {
  List<MileageRecord> _records = [];
  final String _prefKey = 'mileage_records_v2';

  List<MileageRecord> get records => [..._records];

  MileageProvider() {
    loadRecords();
  }

  Future<void> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recordsJson = prefs.getString(_prefKey);
    if (recordsJson != null) {
      final List<dynamic> decoded = jsonDecode(recordsJson);
      _records = decoded.map((item) => MileageRecord.fromJson(item)).toList();
      _records.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  Future<void> addRecord({
    required double odometerReading,
    required double fuelLiters,
    required double pricePerLiter,
  }) async {
    final newRecord = MileageRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      odometerReading: odometerReading,
      fuelLiters: fuelLiters,
      pricePerLiter: pricePerLiter,
      date: DateTime.now(),
    );
    _records.insert(0, newRecord);
    _records.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _saveRecords();
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((rec) => rec.id == id);
    notifyListeners();
    await _saveRecords();
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_records.map((r) => r.toJson()).toList());
    await prefs.setString(_prefKey, encoded);
  }

  List<MileageComparison> get comparisons {
    List<MileageComparison> list = [];
    for (int i = 0; i < _records.length; i++) {
      MileageRecord current = _records[i];
      MileageRecord? previous;
      
      // Since records are sorted newest to oldest, the "previous" record 
      // chronologically is at index i + 1
      if (i + 1 < _records.length) {
        previous = _records[i + 1];
      }
      
      list.add(MileageComparison(current: current, previous: previous));
    }
    return list;
  }

  double get averageMileage {
    final comps = comparisons.where((c) => c.previous != null).toList();
    if (comps.isEmpty) return 0.0;
    
    double totalDistance = 0;
    double totalFuel = 0;
    for (var c in comps) {
      totalDistance += c.distanceTraveled;
      totalFuel += c.current.fuelLiters;
    }
    return totalDistance / totalFuel;
  }

  double get totalSpent => _records.fold(0, (sum, r) => sum + r.totalCost);

  double get averageCostPerKm {
    final comps = comparisons.where((c) => c.previous != null).toList();
    if (comps.isEmpty) return 0.0;

    double totalDistance = 0;
    double totalCost = 0;
    for (var c in comps) {
      totalDistance += c.distanceTraveled;
      totalCost += c.current.totalCost;
    }
    return totalDistance > 0 ? totalCost / totalDistance : 0.0;
  }
}
