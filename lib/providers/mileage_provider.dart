import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mileage_model.dart';
import 'auth_provider.dart';
import 'bike_provider.dart';

class MileageState {
  final List<MileageRecord> records;
  final bool isLoading;

  const MileageState({
    this.records = const [],
    this.isLoading = false,
  });

  MileageState copyWith({
    List<MileageRecord>? records,
    bool? isLoading,
  }) {
    return MileageState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<MileageComparison> get comparisons {
    final List<MileageComparison> list = [];
    for (int i = 0; i < records.length; i++) {
      final current = records[i];
      MileageRecord? previous;
      if (i + 1 < records.length) {
        previous = records[i + 1];
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
    for (final c in comps) {
      totalDistance += c.distanceTraveled;
      totalFuel += c.current.fuelLiters;
    }
    return totalFuel > 0 ? totalDistance / totalFuel : 0.0;
  }

  double get totalSpent => records.fold(0, (sum, r) => sum + r.totalCost);

  double get averageCostPerKm {
    final comps = comparisons.where((c) => c.previous != null).toList();
    if (comps.isEmpty) return 0.0;

    double totalDistance = 0;
    double totalCost = 0;
    for (final c in comps) {
      totalDistance += c.distanceTraveled;
      totalCost += c.current.totalCost;
    }
    return totalDistance > 0 ? totalCost / totalDistance : 0.0;
  }
}

class MileageNotifier extends Notifier<MileageState> {
  static const String _basePrefKey = 'mileage_records_v2';

  String _getUserPrefKey([String? uid]) {
    final userId = uid ?? ref.read(currentUserProvider)?.uid;
    if (userId == null || userId.isEmpty) return _basePrefKey;
    return '${_basePrefKey}_$userId';
  }

  @override
  MileageState build() {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const MileageState();
    }
    _loadRecordsForUser(user.uid);
    return const MileageState(isLoading: true);
  }

  Future<void> _loadRecordsForUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = '${_basePrefKey}_$userId';
      String? recordsJson = prefs.getString(userKey);

      // Graceful migration from legacy non-scoped key if user has no scoped key
      if (recordsJson == null && prefs.containsKey(_basePrefKey)) {
        recordsJson = prefs.getString(_basePrefKey);
        if (recordsJson != null) {
          await prefs.setString(userKey, recordsJson);
        }
      }

      if (recordsJson != null) {
        final List<dynamic> decoded = jsonDecode(recordsJson);
        final records = decoded.map((item) => MileageRecord.fromJson(item)).toList();
        records.sort((a, b) => b.date.compareTo(a.date));
        state = MileageState(records: records, isLoading: false);
      } else {
        state = const MileageState(records: [], isLoading: false);
      }
    } catch (e) {
      debugPrint('Error loading mileage records: $e');
      state = const MileageState(records: [], isLoading: false);
    }
  }

  Future<void> addRecord({
    required double odometerReading,
    required double fuelLiters,
    required double pricePerLiter,
    String? bikeName,
  }) async {
    final activeBike = bikeName ?? ref.read(bikeProvider).selectedBike?.name;
    final newRecord = MileageRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      odometerReading: odometerReading,
      fuelLiters: fuelLiters,
      pricePerLiter: pricePerLiter,
      date: DateTime.now(),
      bikeName: activeBike,
    );
    final updated = [newRecord, ...state.records];
    updated.sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(records: updated);
    await _saveRecords();
  }

  Future<void> deleteRecord(String id) async {
    final updated = state.records.where((rec) => rec.id != id).toList();
    state = state.copyWith(records: updated);
    await _saveRecords();
  }

  Future<void> _saveRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getUserPrefKey();
      final String encoded = jsonEncode(state.records.map((r) => r.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (e) {
      debugPrint('Error saving mileage records: $e');
    }
  }
}

final mileageProvider = NotifierProvider<MileageNotifier, MileageState>(
  MileageNotifier.new,
);

/// MileageState scoped to the currently active bike
final activeMileageStateProvider = Provider<MileageState>((ref) {
  final baseState = ref.watch(mileageProvider);
  final selectedBike = ref.watch(bikeProvider).selectedBike;

  if (selectedBike == null) return baseState;

  final bikeRecords = baseState.records.where((r) {
    if (r.bikeName == null || r.bikeName!.isEmpty) return true; // allow legacy
    return r.bikeName!.trim().toLowerCase() == selectedBike.name.trim().toLowerCase();
  }).toList();

  return MileageState(
    records: bikeRecords,
    isLoading: baseState.isLoading,
  );
});

