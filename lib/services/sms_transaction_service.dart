import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/detected_transaction_model.dart';

class SmsTransactionState {
  final DetectedTransaction? detectedTransaction;
  final List<DetectedTransaction> pendingQueue;
  final bool isListening;
  final bool isScanning;

  const SmsTransactionState({
    this.detectedTransaction,
    this.pendingQueue = const [],
    this.isListening = false,
    this.isScanning = false,
  });

  SmsTransactionState copyWith({
    DetectedTransaction? Function()? detectedTransaction,
    List<DetectedTransaction>? pendingQueue,
    bool? isListening,
    bool? isScanning,
  }) {
    return SmsTransactionState(
      detectedTransaction: detectedTransaction != null ? detectedTransaction() : this.detectedTransaction,
      pendingQueue: pendingQueue ?? this.pendingQueue,
      isListening: isListening ?? this.isListening,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class SmsTransactionNotifier extends Notifier<SmsTransactionState> {
  static const MethodChannel _channel = MethodChannel('com.motologg.app/sms_expense');

  @override
  SmsTransactionState build() {
    if (!kIsWeb && Platform.isAndroid) {
      _initChannelListener();
      _checkInitialTransaction().then((_) {
        syncMissedTransactions();
      });
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
            _enqueueOrShow(tx);
          }
        } catch (e) {
          debugPrint('Error parsing detected transaction: $e');
        }
      }
    });
  }

  void _enqueueOrShow(DetectedTransaction tx) {
    if (state.detectedTransaction == null) {
      state = state.copyWith(detectedTransaction: () => tx);
    } else {
      state = state.copyWith(
        pendingQueue: [...state.pendingQueue, tx],
      );
    }
  }

  Future<void> _checkInitialTransaction() async {
    try {
      final initial = await _channel.invokeMapMethod<dynamic, dynamic>('getInitialTransaction');
      if (initial != null) {
        final tx = DetectedTransaction.fromMap(initial);
        _enqueueOrShow(tx);
        await _channel.invokeMethod('clearPendingTransaction');
      }
    } catch (e) {
      debugPrint('Error fetching initial transaction: $e');
    }
  }

  /// Scans the system SMS inbox for debit transactions received while app was closed.
  Future<List<DetectedTransaction>> syncMissedTransactions({int lookbackHours = 48}) async {
    if (kIsWeb || !Platform.isAndroid) return [];
    try {
      state = state.copyWith(isScanning: true);
      final rawList = await _channel.invokeListMethod<dynamic>(
        'scanMissedSms',
        {'lookbackHours': lookbackHours},
      );
      if (rawList != null && rawList.isNotEmpty) {
        final txList = <DetectedTransaction>[];
        for (final item in rawList) {
          if (item is Map) {
            try {
              txList.add(DetectedTransaction.fromMap(item));
            } catch (e) {
              debugPrint('Error parsing missed transaction item: $e');
            }
          }
        }
        for (final tx in txList) {
          _enqueueOrShow(tx);
        }
        return txList;
      }
    } catch (e) {
      debugPrint('Error syncing missed SMS: $e');
    } finally {
      state = state.copyWith(isScanning: false);
    }
    return [];
  }

  /// Manually checks for any pending transaction from notification tap.
  Future<DetectedTransaction?> pollPendingTransaction() async {
    if (!Platform.isAndroid) return null;
    try {
      final initial = await _channel.invokeMapMethod<dynamic, dynamic>('getInitialTransaction');
      if (initial != null) {
        final tx = DetectedTransaction.fromMap(initial);
        _enqueueOrShow(tx);
        await _channel.invokeMethod('clearPendingTransaction');
        return tx;
      }
    } catch (e) {
      debugPrint('Error polling pending transaction: $e');
    }
    return null;
  }

  /// Clears the current transaction once confirmed or dismissed by user,
  /// and promotes the next transaction from the queue if present.
  void clearTransaction() {
    if (state.pendingQueue.isNotEmpty) {
      final nextTx = state.pendingQueue.first;
      final remaining = state.pendingQueue.sublist(1);
      state = state.copyWith(
        detectedTransaction: () => nextTx,
        pendingQueue: remaining,
      );
    } else {
      state = state.copyWith(detectedTransaction: () => null);
    }
  }

  void clearAll() {
    state = const SmsTransactionState(isListening: true);
  }
}

final smsTransactionProvider =
    NotifierProvider<SmsTransactionNotifier, SmsTransactionState>(
  SmsTransactionNotifier.new,
);
