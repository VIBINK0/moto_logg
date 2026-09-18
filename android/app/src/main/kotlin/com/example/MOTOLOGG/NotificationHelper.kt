package com.example.MOTOLOGG

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.util.Locale

object NotificationHelper {

    const val CHANNEL_ID = "expense_detection_channel"
    private const val CHANNEL_NAME = "Expense Alerts"
    private const val CHANNEL_DESC = "Notifications for detected bank transaction expenses"

    const val EXTRA_IS_DETECTED_EXPENSE = "is_detected_expense"
    const val EXTRA_AMOUNT = "amount"
    const val EXTRA_MERCHANT = "merchant"
    const val EXTRA_PAYMENT_METHOD = "paymentMethod"
    const val EXTRA_TRANSACTION_ID = "transactionId"
    const val EXTRA_TRANSACTION_DATE = "transactionDate"
    const val EXTRA_RAW_BODY = "rawBody"
    const val EXTRA_SENDER = "sender"

    private const val PENDING_TX_PREFS = "moto_logg_pending_tx"
    private const val KEY_PENDING_TX_JSON = "pending_transaction_json"

    fun showNotification(context: Context, transaction: ParsedTransaction) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESC
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Save to pending store for cold start retrieval
        savePendingTransaction(context, transaction)

        // Target Intent pointing to MainActivity
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "ACTION_VIEW_DETECTED_EXPENSE"
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_IS_DETECTED_EXPENSE, true)
            putExtra(EXTRA_AMOUNT, transaction.amount)
            putExtra(EXTRA_MERCHANT, transaction.merchant)
            putExtra(EXTRA_PAYMENT_METHOD, transaction.paymentMethod)
            putExtra(EXTRA_TRANSACTION_ID, transaction.transactionId)
            putExtra(EXTRA_TRANSACTION_DATE, transaction.transactionDate.time)
            putExtra(EXTRA_RAW_BODY, transaction.rawBody)
            putExtra(EXTRA_SENDER, transaction.sender)
        }

        val notificationId = (System.currentTimeMillis() % 100000).toInt()
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val merchantName = transaction.merchant ?: "Merchant"
        val formattedAmount = String.format(Locale.ENGLISH, "₹%.2f", transaction.amount)

        // Use standard app icon or fallback
        val iconRes = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName)
            .let { if (it != 0) it else android.R.drawable.stat_notify_more }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle("💸 Expense detected")
            .setContentText("$formattedAmount spent at $merchantName")
            .setSubText("Tap to review")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("$formattedAmount spent at $merchantName via ${transaction.paymentMethod ?: "Bank"}\nTap to confirm and add to your expenses.")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_EVENT)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(notificationId, notification)
    }

    private fun savePendingTransaction(context: Context, transaction: ParsedTransaction) {
        val prefs: SharedPreferences = context.getSharedPreferences(PENDING_TX_PREFS, Context.MODE_PRIVATE)
        val json = JSONObject().apply {
            put(EXTRA_AMOUNT, transaction.amount)
            put(EXTRA_MERCHANT, transaction.merchant ?: "")
            put(EXTRA_PAYMENT_METHOD, transaction.paymentMethod ?: "")
            put(EXTRA_TRANSACTION_ID, transaction.transactionId ?: "")
            put(EXTRA_TRANSACTION_DATE, transaction.transactionDate.time)
            put(EXTRA_RAW_BODY, transaction.rawBody)
            put(EXTRA_SENDER, transaction.sender)
        }
        prefs.edit().putString(KEY_PENDING_TX_JSON, json.toString()).apply()
    }

    fun getPendingTransaction(context: Context): Map<String, Any?>? {
        val prefs: SharedPreferences = context.getSharedPreferences(PENDING_TX_PREFS, Context.MODE_PRIVATE)
        val jsonStr = prefs.getString(KEY_PENDING_TX_JSON, null) ?: return null
        return try {
            val json = JSONObject(jsonStr)
            mapOf(
                EXTRA_AMOUNT to json.optDouble(EXTRA_AMOUNT, 0.0),
                EXTRA_MERCHANT to json.optString(EXTRA_MERCHANT).ifBlank { null },
                EXTRA_PAYMENT_METHOD to json.optString(EXTRA_PAYMENT_METHOD).ifBlank { null },
                EXTRA_TRANSACTION_ID to json.optString(EXTRA_TRANSACTION_ID).ifBlank { null },
                EXTRA_TRANSACTION_DATE to json.optLong(EXTRA_TRANSACTION_DATE, System.currentTimeMillis()),
                EXTRA_RAW_BODY to json.optString(EXTRA_RAW_BODY),
                EXTRA_SENDER to json.optString(EXTRA_SENDER)
            )
        } catch (_: Exception) {
            null
        }
    }

    fun clearPendingTransaction(context: Context) {
        val prefs: SharedPreferences = context.getSharedPreferences(PENDING_TX_PREFS, Context.MODE_PRIVATE)
        prefs.edit().remove(KEY_PENDING_TX_JSON).apply()
    }
}
