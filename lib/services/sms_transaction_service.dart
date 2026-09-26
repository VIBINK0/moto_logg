import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/detected_transaction_model.dart';

class SmsTransactionState {
  final DetectedTransaction? detectedTransaction;
  final bool isListening;

  const SmsTransactionState({
    this.detectedTransaction,
    this.isListening = false,
  });

  SmsTransactionState copyWith({
    DetectedTransaction? Function()? detectedTransaction,
    bool? isListening,
  }) {
    return SmsTransactionState(
      detectedTransaction: detectedTransaction != null ? detectedTransaction() : this.detectedTransaction,
      isListening: isListening ?? this.isListening,
    );
  }
}

class SmsTransactionNotifier extends Notifier<SmsTransactionState> {
  static const MethodChannel _channel = MethodChannel('com.motologg.app/sms_expense');

  @override
  SmsTransactionState build() {
    if (!kIsWeb&&Platform.isAndroid) {
      _initChannelListener();
      _checkInitialTransaction();
    }
    return const SmsTransactionState(isListening: true);
  }

  void _initChannelListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTransactionDetected') {
        try {
          final arguments = call.arguments;
          if (arguments is Map) {
            final tx = DetectedTransaction.fromMap(arguments);
            state = state.copyWith(detectedTransaction: () => tx);
          }
        } catch (e) {
          debugPrint('Error parsing detected transaction: $e');
        }
      }
    });
  }

  Future<void> _checkInitialTransaction() async {
    try {
      final initial = await _channel.invokeMapMethod<dynamic, dynamic>('getInitialTransaction');
      if (initial != null) {
        final tx = DetectedTransaction.fromMap(initial);
        state = state.copyWith(detectedTransaction: () => tx);
        await _channel.invokeMethod('clearPendingTransaction');
      }
    } catch (e) {
      debugPrint('Error fetching initial transaction: $e');
    }
  }

  /// Manually checks for any pending transaction from notification tap.
  Future<DetectedTransaction?> pollPendingTransaction() async {
    if (!Platform.isAndroid) return null;
    try {
      final initial = await _channel.invokeMapMethod<dynamic, dynamic>('getInitialTransaction');
      if (initial != null) {
        final tx = DetectedTransaction.fromMap(initial);
        state = state.copyWith(detectedTransaction: () => tx);
        await _channel.invokeMethod('clearPendingTransaction');
        return tx;
      }
    } catch (e) {
      debugPrint('Error polling pending transaction: $e');
    }
    return null;
  }

  /// Clears the current transaction once confirmed or dismissed by user.
  void clearTransaction() {
    state = state.copyWith(detectedTransaction: () => null);
  }
}

final smsTransactionProvider =
    NotifierProvider<SmsTransactionNotifier, SmsTransactionState>(
  SmsTransactionNotifier.new,
);
