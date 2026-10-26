// lib/services/bike_storage_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike_model.dart';

class BikeStorageService {
  static const String _keyPrefix = 'selected_bike_';
  static const String _ownedKeyPrefix = 'owned_bikes_';

  /// Get storage key for specific user
  static String _getUserKey(String userId) => '$_keyPrefix$userId';
  static String _getOwnedUserKey(String userId) => '$_ownedKeyPrefix$userId';

  /// Save selected bike for a user
  static Future<bool> saveSelectedBike({
    required String userId,
    required BikeModel bike,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bikeJson = jsonEncode(bike.toJson());
      await prefs.setString(_getUserKey(userId), bikeJson);
      // Synchronize common keys for native background services (Notifications, Quick Log)
      await prefs.setString('selected_bike_name', bike.name);
      return true;
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

  /// Save the user's list of owned bikes in Firebase Firestore and SharedPreferences
  static Future<bool> saveOwnedBikes({
    required String userId,
    required List<String> bikes,
  }) async {
    try {
      final cleanList = bikes.map((b) => b.trim()).where((b) => b.isNotEmpty).toSet().toList();
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(cleanList);

      await prefs.setString(_getOwnedUserKey(userId), jsonStr);
      await prefs.setStringList('user_owned_bikes', cleanList);
      await prefs.setString('user_owned_bikes_json', jsonStr);

      // Persist to Firebase Firestore under users/{userId}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({'ownedBikes': cleanList}, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the user's owned bikes (checks local cache first, then Firestore)
  static Future<List<String>> getOwnedBikes(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Try local cache first for instant UI response
      final localJson = prefs.getString(_getOwnedUserKey(userId));
      if (localJson != null && localJson.isNotEmpty) {
        final decoded = jsonDecode(localJson);
        if (decoded is List && decoded.isNotEmpty) {
          final list = decoded.map((e) => e.toString()).toList();
          if (prefs.getString('user_owned_bikes_json') == null) {
            await prefs.setString('user_owned_bikes_json', localJson);
            await prefs.setStringList('user_owned_bikes', list);
          }
          return list;
        }
      }

      // 2. Query Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        final rawOwned = data?['ownedBikes'] as List<dynamic>?;
        if (rawOwned != null && rawOwned.isNotEmpty) {
          final list = rawOwned.map((e) => e.toString()).toList();
          final jsonStr = jsonEncode(list);
          await prefs.setString(_getOwnedUserKey(userId), jsonStr);
          await prefs.setStringList('user_owned_bikes', list);
          await prefs.setString('user_owned_bikes_json', jsonStr);
          return list;
        }
      }

      // 3. Fallback: check if user has a selected bike
      final selected = await getSelectedBike(userId);
      if (selected != null) {
        final list = [selected.name];
        await saveOwnedBikes(userId: userId, bikes: list);
        return list;
      }

      // 4. Default to default bike
      final list = [BikeModel.defaultBike.name];
      await saveOwnedBikes(userId: userId, bikes: list);
      return list;
    } catch (e) {
      return [BikeModel.defaultBike.name];
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
      await prefs.remove(_getUserKey(userId));
      await prefs.remove(_getOwnedUserKey(userId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all bike selections (optional: full reset)
  static Future<void> clearAllSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix) || key.startsWith(_ownedKeyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
