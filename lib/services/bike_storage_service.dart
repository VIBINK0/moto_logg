// lib/services/bike_storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike_model.dart';

class BikeStorageService {
  static const String _keyPrefix = 'selected_bike_';

  /// Get storage key for specific user
  static String _getUserKey(String userId) => '$_keyPrefix$userId';

  /// Save selected bike for a user
  static Future<bool> saveSelectedBike({
    required String userId,
    required BikeModel bike,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bikeJson = jsonEncode(bike.toJson());
      return await prefs.setString(_getUserKey(userId), bikeJson);
    } catch (e) {
      return false;
    }
  }

  /// Get selected bike for a user
  static Future<BikeModel?> getSelectedBike(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bikeJson = prefs.getString(_getUserKey(userId));
      if (bikeJson == null) return null;
      return BikeModel.fromJson(jsonDecode(bikeJson) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Check if user has a selected bike
  static Future<bool> hasSelectedBike(String userId) async {
    final bike = await getSelectedBike(userId);
    return bike != null;
  }

  /// Clear bike selection for a user (call on logout)
  static Future<bool> clearSelectedBike(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_getUserKey(userId));
    } catch (e) {
      return false;
    }
  }

  /// Clear all bike selections (optional: full reset)
  static Future<void> clearAllSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
