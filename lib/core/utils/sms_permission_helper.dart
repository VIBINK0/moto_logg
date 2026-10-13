import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SmsPermissionStatus {
  final bool receiveSms;
  final bool postNotifications;
  final bool isBatteryOptimizationIgnored;

  const SmsPermissionStatus({
    required this.receiveSms,
    required this.postNotifications,
    this.isBatteryOptimizationIgnored = false,
  });

  bool get isFullyGranted => receiveSms && postNotifications;
  bool get isFullyConfigured => isFullyGranted && isBatteryOptimizationIgnored;
}

class SmsPermissionHelper {
  static const MethodChannel _channel = MethodChannel('com.motologg.app/sms_expense');

  /// Checks the current permission and battery optimization states on Android.
  static Future<SmsPermissionStatus> checkPermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const SmsPermissionStatus(
        receiveSms: false,
        postNotifications: false,
        isBatteryOptimizationIgnored: true,
      );
    }

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('checkPermissions');
      if (result == null) {
        return const SmsPermissionStatus(receiveSms: false, postNotifications: false);
      }

      return SmsPermissionStatus(
        receiveSms: result['receiveSms'] as bool? ?? false,
        postNotifications: result['postNotifications'] as bool? ?? false,
        isBatteryOptimizationIgnored: result['isBatteryOptimizationIgnored'] as bool? ?? false,
      );
    } on PlatformException {
      return const SmsPermissionStatus(receiveSms: false, postNotifications: false);
    }
  }

  /// Triggers runtime permission request for RECEIVE_SMS and POST_NOTIFICATIONS.
  static Future<bool> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      final granted = await _channel.invokeMethod<bool>('requestPermissions');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks whether battery optimization is ignored (unrestricted background execution).
  static Future<bool> isBatteryOptimizationIgnored() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final ignored = await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return ignored ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Requests ignoring battery optimizations to keep SMS receiver alive in background.
  static Future<bool> requestIgnoreBatteryOptimization() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimization');
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the app system settings so user can manage Autostart and Battery permissions.
  static Future<bool> openBatterySettings() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('openBatterySettings');
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }
}
