import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _keyHasSeenFeatures = 'has_seen_features_overview';

  /// Check whether the user has already seen the features overview.
  static Future<bool> hasSeenFeatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyHasSeenFeatures) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark the features overview as seen so it only displays once.
  static Future<void> markFeaturesSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasSeenFeatures, true);
    } catch (_) {}
  }

  /// Reset the flag (for testing or user re-request).
  static Future<void> resetFeaturesSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHasSeenFeatures);
    } catch (_) {}
  }
}
