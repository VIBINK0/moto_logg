package com.example.expanse_tracker

import android.content.Context
import android.net.Uri
import android.provider.Telephony
import android.util.Log
import java.util.Date

object SmsInboxScanner {

    private const val TAG = "SmsInboxScanner"

    /**
     * Scans the system SMS inbox for debit expense transactions received in the given window.
     * Unprocessed transactions are marked in DuplicateManager and returned.
     */
    fun scanRecentSms(context: Context, lookbackHours: Long = 48): List<ParsedTransaction> {
        val detected = mutableListOf<ParsedTransaction>()
        val uri = Uri.parse("content://sms/inbox")
        val cutoffTime = System.currentTimeMillis() - (lookbackHours * 60 * 60 * 1000)

        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE
        )
        val selection = "${Telephony.Sms.DATE} >= ?"
        val selectionArgs = arrayOf(cutoffTime.toString())
        val sortOrder = "${Telephony.Sms.DATE} DESC"

        try {
            val cursor = context.contentResolver.query(
                uri,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )

            cursor?.use {
                val addressIdx = it.getColumnIndex(Telephony.Sms.ADDRESS)
                val bodyIdx = it.getColumnIndex(Telephony.Sms.BODY)
                val dateIdx = it.getColumnIndex(Telephony.Sms.DATE)

                while (it.moveToNext()) {
                    val address = it.getString(addressIdx) ?: "UNKNOWN"
                    val body = it.getString(bodyIdx) ?: ""
                    val dateMillis = it.getLong(dateIdx)

                    if (body.isBlank()) continue

                    val parsed = TransactionParser.parse(body, address) ?: continue

                    // Prefer the SMS message received date from Telephony provider if parser defaulted
                    val actualDate = Date(dateMillis)
                    val finalTx = parsed.copy(transactionDate = actualDate)

                    val fingerprint = DuplicateManager.getFingerprint(finalTx)
                    if (!DuplicateManager.isDuplicate(context, fingerprint)) {
                        DuplicateManager.markProcessed(context, fingerprint)
                        detected.add(finalTx)
                        Log.i(TAG, "Catch-up scan found new expense: ₹${finalTx.amount} from $address (Date: $actualDate)")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning SMS inbox for missed expenses", e)
        }

        return detected
    }
}
