package com.example.MOTOLOGG

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Locale

object DuplicateManager {

    private const val PREFS_NAME = "moto_logg_sms_duplicates"
    private const val KEY_PROCESSED_LIST = "processed_fingerprints"
    private const val MAX_ENTRIES = 200

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    /**
     * Computes a unique fingerprint for a transaction.
     * Uses reference/transaction ID if present, otherwise creates a composite hash.
     */
    fun getFingerprint(transaction: ParsedTransaction): String {
        val ref = transaction.transactionId?.trim()
        if (!ref.isNullOrBlank()) {
            return "ref_${ref.uppercase()}"
        }

        // Fallback composite: amount + date (YYYY-MM-DD) + merchant
        val dayFormat = SimpleDateFormat("yyyy-MM-dd", Locale.ENGLISH)
        val dayStr = dayFormat.format(transaction.transactionDate)
        val merchantStr = (transaction.merchant ?: "UNKNOWN").trim().uppercase()
        val composite = "fp_%.2f_%s_%s".format(Locale.ENGLISH, transaction.amount, dayStr, merchantStr)

        return hashString(composite)
    }

    /**
     * Checks if this fingerprint has already been processed.
     */
    fun isDuplicate(context: Context, fingerprint: String): Boolean {
        val prefs = getPrefs(context)
        val jsonStr = prefs.getString(KEY_PROCESSED_LIST, null) ?: return false

        try {
            val array = JSONArray(jsonStr)
            for (i in 0 until array.length()) {
                if (array.getString(i) == fingerprint) {
                    return true
                }
            }
        } catch (_: Exception) {
            // If corrupt, consider not duplicate
        }
        return false
    }

    /**
     * Marks a fingerprint as processed and prunes older entries to maintain MAX_ENTRIES.
     */
    fun markProcessed(context: Context, fingerprint: String) {
        val prefs = getPrefs(context)
        val jsonStr = prefs.getString(KEY_PROCESSED_LIST, null)

        val list = mutableListOf<String>()
        if (jsonStr != null) {
            try {
                val array = JSONArray(jsonStr)
                for (i in 0 until array.length()) {
                    list.add(array.getString(i))
                }
            } catch (_: Exception) {
                // reset if corrupt
            }
        }

        // Add to front if not already present
        if (!list.contains(fingerprint)) {
            list.add(0, fingerprint)
            while (list.size > MAX_ENTRIES) {
                list.removeAt(list.size - 1)
            }

            val newArray = JSONArray()
            for (item in list) {
                newArray.put(item)
            }
            prefs.edit().putString(KEY_PROCESSED_LIST, newArray.toString()).apply()
        }
    }

    private fun hashString(input: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }.take(16)
    }
}
