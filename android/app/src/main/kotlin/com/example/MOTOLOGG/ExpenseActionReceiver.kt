package com.example.MOTOLOGG

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import java.util.Date
import java.util.Locale

class ExpenseActionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "ExpenseActionReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != NotificationHelper.ACTION_SAVE_EXPENSE) {
            return
        }

        val rawCategory = intent.getStringExtra(NotificationHelper.EXTRA_CATEGORY) ?: "fuel"
        val notificationId = intent.getIntExtra(NotificationHelper.EXTRA_NOTIFICATION_ID, 0)
        val amount = intent.getDoubleExtra(NotificationHelper.EXTRA_AMOUNT, 0.0)
        val merchant = intent.getStringExtra(NotificationHelper.EXTRA_MERCHANT)
        val paymentMethod = intent.getStringExtra(NotificationHelper.EXTRA_PAYMENT_METHOD)
        val transactionId = intent.getStringExtra(NotificationHelper.EXTRA_TRANSACTION_ID)
        val transactionDate = intent.getLongExtra(
            NotificationHelper.EXTRA_TRANSACTION_DATE,
            System.currentTimeMillis()
        )

        // Get user inline notes from RemoteInput
        val remoteInputResults = RemoteInput.getResultsFromIntent(intent)
        val rawInput = remoteInputResults?.getCharSequence(NotificationHelper.EXTRA_KEY_NOTE)?.toString()?.trim()

        // Filter out preset "Save" choices so they aren't added as literal note text
        val customNotes = if (rawInput.isNullOrBlank() ||
            rawInput.equals("Save", ignoreCase = true) ||
            rawInput.equals("Save Expense", ignoreCase = true) ||
            rawInput.equals("Log", ignoreCase = true) ||
            rawInput.equals("Log Expense", ignoreCase = true)
        ) {
            null
        } else {
            rawInput
        }

        // Resolve category: if category is "acc_or_mods", check notes for modification keywords
        val resolvedCategory = when (rawCategory) {
            "acc_or_mods" -> {
                if (!customNotes.isNullOrBlank() &&
                    (customNotes.contains("mod", ignoreCase = true) ||
                     customNotes.contains("modification", ignoreCase = true) ||
                     customNotes.contains("tuning", ignoreCase = true))
                ) {
                    "modifications"
                } else {
                    "accessories"
                }
            }
            else -> rawCategory
        }

        // Build note string combining custom notes (if entered) with merchant & reference
        val notesBuilder = StringBuilder()
        if (!customNotes.isNullOrBlank()) {
            notesBuilder.append(customNotes)
        }
        if (!merchant.isNullOrBlank()) {
            if (notesBuilder.isNotEmpty()) notesBuilder.append(" • ")
            notesBuilder.append(merchant)
        }
        if (!transactionId.isNullOrBlank()) {
            if (notesBuilder.isNotEmpty()) notesBuilder.append(" • ")
            notesBuilder.append("Ref: ").append(transactionId)
        }
        val finalNotes = if (notesBuilder.isNotEmpty()) notesBuilder.toString() else null

        Log.i(TAG, "Saving expense from notification: amount=₹$amount, category=$resolvedCategory, notes=$finalNotes")

        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser == null) {
            Log.w(TAG, "No logged in user found when attempting to save expense from notification")
            showFeedbackNotification(
                context,
                notificationId,
                "⚠️ Save Failed",
                "Please log in to MotoLogg to save detected expenses."
            )
            return
        }

        val expenseData = hashMapOf<String, Any?>(
            "category" to resolvedCategory,
            "amount" to amount,
            "date" to Timestamp(Date(transactionDate)),
            "notes" to finalNotes
        )

        FirebaseFirestore.getInstance()
            .collection("users")
            .document(currentUser.uid)
            .collection("expenses")
            .add(expenseData)
            .addOnSuccessListener {
                Log.i(TAG, "Successfully saved expense directly from notification")
                NotificationHelper.clearPendingTransaction(context)

                val displayCategoryLabel = when (resolvedCategory) {
                    "modifications" -> "Modifications"
                    "accessories" -> "Accessories"
                    "service" -> "Service"
                    else -> "Fuel"
                }
                val formattedAmount = String.format(Locale.ENGLISH, "₹%.2f", amount)

                showFeedbackNotification(
                    context,
                    notificationId,
                    "✅ Expense Saved",
                    "$formattedAmount saved as $displayCategoryLabel" + (if (customNotes != null) " • \"$customNotes\"" else "")
                )
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to save expense from notification", e)
                showFeedbackNotification(
                    context,
                    notificationId,
                    "⚠️ Failed to Save Expense",
                    "Tap to review and save in the app."
                )
            }
    }

    private fun showFeedbackNotification(
        context: Context,
        notificationId: Int,
        title: String,
        message: String
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create intent to open MainActivity when the notification is tapped
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val contentPendingIntent = PendingIntent.getActivity(
            context,
            (System.currentTimeMillis() % 100000).toInt(),
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val iconRes = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName)
            .let { if (it != 0) it else android.R.drawable.stat_notify_more }

        val notification = NotificationCompat.Builder(context, NotificationHelper.CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(contentPendingIntent)
            .build()

        notificationManager.notify(notificationId, notification)
    }
}
