package com.example.MOTOLOGG

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.regex.Pattern

data class ParsedTransaction(
    val amount: Double,
    val merchant: String?,
    val paymentMethod: String?,
    val transactionId: String?,
    val transactionDate: Date,
    val rawBody: String,
    val sender: String
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "amount" to amount,
            "merchant" to merchant,
            "paymentMethod" to paymentMethod,
            "transactionId" to transactionId,
            "transactionDate" to transactionDate.time,
            "rawBody" to rawBody,
            "sender" to sender
        )
    }
}

object TransactionParser {

    // 1. Patterns that indicate this is NOT an expense transaction
    private val EXCLUDE_PATTERNS = listOf(
        // OTPs & verification codes
        Pattern.compile("\\b(otp|one time password|verification code|security code|secret code|auth code)\\b", Pattern.CASE_INSENSITIVE),
        Pattern.compile("\\b(do not share|don't share|never share|valid for)\\b", Pattern.CASE_INSENSITIVE),
        // Credits, deposits, refunds, salary received
        Pattern.compile("\\b(credited|credit of|deposited|deposit of|salary credited|refund credited|cashback received)\\b", Pattern.CASE_INSENSITIVE),
        // Failed / cancelled transactions
        Pattern.compile("\\b(declined|failed|failure|unsuccessful|cancelled|reversed|reversal)\\b", Pattern.CASE_INSENSITIVE),
        // Pure promotional / marketing messages
        Pattern.compile("\\b(pre-approved|apply now|congratulations|discount up to|flat discount|instant loan)\\b", Pattern.CASE_INSENSITIVE)
    )

    // 2. Debit indicators (Must match at least one)
    private val DEBIT_INDICATOR = Pattern.compile(
        "\\b(debited|debited by|debited with|debited for|debit of|paid|payment of|payment to|payment for|sent|transferred|transfer of|spent|deducted|purchase of|purchase|txn of|transaction of|charged|withdrawn)\\b",
        Pattern.CASE_INSENSITIVE
    )

    // 3. Amount patterns (Handles Rs. 500, Rs.500.00, INR 500, ₹500, Rs 1,500.50)
    private val AMOUNT_PATTERNS = listOf(
        Pattern.compile("(?:Rs\\.?|INR|₹)\\s*([0-9,]+(?:\\.[0-9]{1,2})?)", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(?:debited\\s+(?:by|for|with)?|spent|paid|txn\\s+of)\\s*(?:Rs\\.?|INR|₹)?\\s*([0-9,]+(?:\\.[0-9]{1,2})?)", Pattern.CASE_INSENSITIVE)
    )

    // 4. Reference / Transaction ID patterns
    private val REF_PATTERNS = listOf(
        Pattern.compile("(?:Ref(?:erence)?\\s*(?:No\\.?|Id\\.?|Num\\.?)?|Txn\\s*(?:Id\\.?|No\\.?)?|UPI\\s*Ref(?:\\s*No\\.?)?|UTR(?:\\s*No\\.?)?|RRN)\\s*[:#\\-]?\\s*([A-Za-z0-9]{6,25})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("\\bUPI/([A-Za-z0-9]+)", Pattern.CASE_INSENSITIVE),
        Pattern.compile("\\b(?:Ref\\s+No)\\s+([0-9]{6,20})\\b", Pattern.CASE_INSENSITIVE),
        Pattern.compile("\\b([0-9]{12})\\b") // Generic 12-digit UPI reference number
    )

    // 5. Merchant / Payee patterns
    private val MERCHANT_PATTERNS = listOf(
        Pattern.compile("(?:to|at|vpa|towards|info|for)\\s+([A-Za-z0-9\\s\\.\\*\\@\\-_&]{2,30}?)(?=\\s+(?:on|ref|ref\\s*no|upi|via|thru|using|avail|bal|a/c|from|for|\\.|;|$))", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(?:spent at|paid to)\\s+([A-Za-z0-9\\s\\.\\*\\@\\-_&]{2,30}?)(?=\\s+(?:on|ref|upi|via|\\.|;|$))", Pattern.CASE_INSENSITIVE),
        Pattern.compile("([a-zA-Z0-9.\\-_]+@[a-zA-Z0-9]+)") // UPI VPA
    )

    // 6. Payment method patterns
    private val UPI_PATTERN = Pattern.compile("\\b(upi|vpa|gpay|phonepe|paytm upi)\\b", Pattern.CASE_INSENSITIVE)
    private val CARD_PATTERN = Pattern.compile("\\b(debit card|credit card|card ending|card xx|ending \\d{4})\\b", Pattern.CASE_INSENSITIVE)
    private val NETBANKING_PATTERN = Pattern.compile("\\b(netbanking|net banking|inb|internet banking)\\b", Pattern.CASE_INSENSITIVE)
    private val ATM_PATTERN = Pattern.compile("\\b(atm|cash withdrawal|atm wdl)\\b", Pattern.CASE_INSENSITIVE)
    private val IMPS_NEFT_PATTERN = Pattern.compile("\\b(imps|neft|rtgs)\\b", Pattern.CASE_INSENSITIVE)

    // 7. Date patterns (supports yyyy-MM-dd, dd-MM-yyyy, etc.)
    private val DATE_PATTERNS = listOf(
        Pair(Pattern.compile("\\b(\\d{4}-\\d{1,2}-\\d{1,2})\\b"), "yyyy-MM-dd"),
        Pair(Pattern.compile("\\b(\\d{4}/\\d{1,2}/\\d{1,2})\\b"), "yyyy/MM/dd"),
        Pair(Pattern.compile("\\b(\\d{1,2}-\\d{1,2}-\\d{2,4})\\b"), "dd-MM-yyyy"),
        Pair(Pattern.compile("\\b(\\d{1,2}/\\d{1,2}/\\d{2,4})\\b"), "dd/MM/yyyy"),
        Pair(Pattern.compile("\\b(\\d{1,2}-[A-Za-z]{3}-\\d{2,4})\\b"), "dd-MMM-yyyy"),
        Pair(Pattern.compile("\\b(\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{2,4})\\b"), "dd MMM yyyy")
    )

    fun parse(smsBody: String, sender: String): ParsedTransaction? {
        if (smsBody.isBlank()) return null

        // Rule 1: Exclude OTPs, credits, declined, or marketing SMS
        for (pattern in EXCLUDE_PATTERNS) {
            if (pattern.matcher(smsBody).find()) {
                return null
            }
        }

        // Rule 2: Must have a debit or payment indicator
        if (!DEBIT_INDICATOR.matcher(smsBody).find()) {
            return null
        }

        // Rule 3: Extract amount
        val amount = extractAmount(smsBody) ?: return null

        // Rule 4: Extract reference/transaction ID
        val transactionId = extractTransactionId(smsBody)

        // Rule 5: Extract merchant/payee
        val merchant = extractMerchant(smsBody, sender)

        // Rule 6: Extract payment method
        val paymentMethod = extractPaymentMethod(smsBody)

        // Rule 7: Extract date or fallback to now
        val transactionDate = extractDate(smsBody) ?: Date()

        return ParsedTransaction(
            amount = amount,
            merchant = merchant,
            paymentMethod = paymentMethod,
            transactionId = transactionId,
            transactionDate = transactionDate,
            rawBody = smsBody,
            sender = sender
        )
    }

    private fun extractAmount(text: String): Double? {
        for (pattern in AMOUNT_PATTERNS) {
            val matcher = pattern.matcher(text)
            if (matcher.find()) {
                val match = matcher.group(1)?.replace(",", "")?.trim()
                val parsed = match?.toDoubleOrNull()
                if (parsed != null && parsed > 0.0) {
                    return parsed
                }
            }
        }
        return null
    }

    private fun extractTransactionId(text: String): String? {
        for (pattern in REF_PATTERNS) {
            val matcher = pattern.matcher(text)
            if (matcher.find()) {
                val ref = matcher.group(1)?.trim()
                if (!ref.isNullOrBlank()) {
                    return ref
                }
            }
        }
        return null
    }

    private val BANK_SIGNATURE_PATTERN = Pattern.compile("(?:immediately|bank|team)[\\s\\-:]+([A-Za-z]{3,12})\\b|-([A-Za-z]{3,10})\\.?$", Pattern.CASE_INSENSITIVE)

    private fun extractMerchant(text: String, sender: String): String? {
        for (pattern in MERCHANT_PATTERNS) {
            val matcher = pattern.matcher(text)
            if (matcher.find()) {
                var candidate = matcher.group(1)?.trim() ?: continue
                // Clean up trailing punctuations
                candidate = candidate.trimEnd('.', ',', ';', ':', '-')
                // Exclude false matches
                val lower = candidate.lowercase()
                if (lower == "your" || lower == "a/c" || lower == "account" || lower.startsWith("acct")) {
                    continue
                }
                if (lower == "payee") {
                    val bank = extractBankName(text, sender)
                    return if (bank != null) "$bank Payee" else "Payee"
                }
                if (candidate.length >= 2) {
                    return candidate.uppercase()
                }
            }
        }

        val bank = extractBankName(text, sender)
        if (bank != null) {
            return bank
        }

        return null
    }

    private fun extractBankName(text: String, sender: String): String? {
        val sigMatcher = BANK_SIGNATURE_PATTERN.matcher(text)
        if (sigMatcher.find()) {
            val name = sigMatcher.group(1) ?: sigMatcher.group(2)
            if (!name.isNullOrBlank()) return name.trim().uppercase()
        }

        val cleanedSender = sender.replace(Regex("^[A-Za-z]{2}-"), "")
        if (cleanedSender.isNotBlank()) {
            val bankCandidate = cleanedSender.take(6).uppercase()
            if (bankCandidate.length >= 3) {
                return bankCandidate
            }
        }
        return null
    }

    private fun extractPaymentMethod(text: String): String {
        return when {
            UPI_PATTERN.matcher(text).find() -> "UPI"
            CARD_PATTERN.matcher(text).find() -> "Debit Card"
            NETBANKING_PATTERN.matcher(text).find() -> "NetBanking"
            ATM_PATTERN.matcher(text).find() -> "Cash / ATM"
            IMPS_NEFT_PATTERN.matcher(text).find() -> "IMPS / NEFT"
            else -> "Bank Transfer"
        }
    }

    private fun extractDate(text: String): Date? {
        for ((pattern, format) in DATE_PATTERNS) {
            val matcher = pattern.matcher(text)
            if (matcher.find()) {
                val dateStr = matcher.group(1) ?: continue
                try {
                    val sdf = SimpleDateFormat(format, Locale.ENGLISH)
                    sdf.isLenient = false
                    val parsed = sdf.parse(dateStr)
                    if (parsed != null) return parsed
                } catch (_: Exception) {
                    // Ignore and try next pattern
                }
            }
        }
        return null
    }
}
