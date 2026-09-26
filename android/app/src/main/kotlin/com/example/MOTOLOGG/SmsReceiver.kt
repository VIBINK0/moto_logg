package com.example.MOTOLOGG

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "MotoLoggSmsReceiver" //U4exDKTb7TULWBln
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }

        Log.i(TAG, "SMS broadcast received: ${intent.action}")

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNullOrEmpty()) {
                Log.w(TAG, "getMessagesFromIntent returned null or empty")
                return
            }

            // Group parts by sender (in case of multipart SMS)
            val senderMap = mutableMapOf<String, StringBuilder>()
            for (sms in messages) {
                if (sms == null) continue
                val sender = sms.displayOriginatingAddress ?: sms.originatingAddress ?: "UNKNOWN"
                val body = sms.displayMessageBody ?: sms.messageBody ?: ""
                val builder = senderMap.getOrPut(sender) { StringBuilder() }
                builder.append(body)
            }

            for ((sender, bodyBuilder) in senderMap) {
                val fullBody = bodyBuilder.toString()
                if (fullBody.isBlank()) continue

                Log.i(TAG, "Processing SMS from: $sender")
                Log.d(TAG, "SMS Body: $fullBody")

                // Parse transaction
                val parsed = TransactionParser.parse(fullBody, sender)
                if (parsed == null) {
                    Log.d(TAG, "SMS did not match debit expense patterns")
                    continue
                }

                Log.i(TAG, "Debit transaction detected: amount=${parsed.amount}, merchant=${parsed.merchant}, method=${parsed.paymentMethod}")

                // Check duplicate
                val fingerprint = DuplicateManager.getFingerprint(parsed)
                if (DuplicateManager.isDuplicate(context, fingerprint)) {
                    Log.i(TAG, "Duplicate transaction ignored: $fingerprint")
                    continue
                }

                // Mark processed
                DuplicateManager.markProcessed(context, fingerprint)

                // Show notification
                NotificationHelper.showNotification(context, parsed)
                Log.i(TAG, "Notification displayed for ₹${parsed.amount}")

                // If MainActivity is active in memory, push live event to Flutter
                MainActivity.sendTransactionToFlutter(parsed)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling incoming SMS", e)
        }
    }
}
