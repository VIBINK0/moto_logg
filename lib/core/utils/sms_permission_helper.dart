import 'dart:io';
import 'package:flutter/services.dart';

class SmsPermissionStatus {
  final bool receiveSms;
  final bool postNotifications;

  const SmsPermissionStatus({
    required this.receiveSms,
    required this.postNotifications,
  });

  bool get isFullyGranted => receiveSms && postNotifications;
}

class SmsPermissionHelper {
  static const MethodChannel _channel = MethodChannel('com.motologg.app/sms_expense');

  /// Checks the current permission states on Android.
  static Future<SmsPermissionStatus> checkPermissions() async {
    if (!Platform.isAndroid) {
      return const SmsPermissionStatus(receiveSms: false, postNotifications: false);
    }

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('checkPermissions');
      if (result == null) {
        return const SmsPermissionStatus(receiveSms: false, postNotifications: false);
      }

      return SmsPermissionStatus(
        receiveSms: result['receiveSms'] as bool? ?? false,
        postNotifications: result['postNotifications'] as bool? ?? false,
      );
    } on PlatformException {
      return const SmsPermissionStatus(receiveSms: false, postNotifications: false);
    }
  }

  /// Triggers runtime permission request for RECEIVE_SMS and POST_NOTIFICATIONS.
  static Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;

    try {
      final granted = await _channel.invokeMethod<bool>('requestPermissions');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }
}
