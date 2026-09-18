package com.example.MOTOLOGG

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.motologg.app/sms_expense"
        private const val PERMISSION_REQUEST_CODE = 1001

        private var currentInstance: WeakReference<MainActivity>? = null
        private var methodChannel: MethodChannel? = null

        fun sendTransactionToFlutter(transaction: ParsedTransaction) {
            Handler(Looper.getMainLooper()).post {
                try {
                    methodChannel?.invokeMethod("onTransactionDetected", transaction.toMap())
                } catch (_: Exception) {
                    // Ignored if engine not ready
                }
            }
        }
    }

    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        currentInstance = WeakReference(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        currentInstance = WeakReference(this)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialTransaction" -> {
                    // Check if launched directly from notification intent
                    val fromIntent = extractTransactionFromIntent(intent)
                    if (fromIntent != null) {
                        // Clear intent flags so repeated calls don't return old transaction
                        intent.removeExtra(NotificationHelper.EXTRA_IS_DETECTED_EXPENSE)
                        NotificationHelper.clearPendingTransaction(applicationContext)
                        result.success(fromIntent)
                    } else {
                        // Fallback to shared prefs pending store
                        val pending = NotificationHelper.getPendingTransaction(applicationContext)
                        result.success(pending)
                    }
                }

                "clearPendingTransaction" -> {
                    NotificationHelper.clearPendingTransaction(applicationContext)
                    result.success(true)
                }

                "checkPermissions" -> {
                    val receiveSms = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECEIVE_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    val readSms = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.READ_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    val postNotifications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }

                    result.success(
                        mapOf(
                            "receiveSms" to (receiveSms && readSms),
                            "postNotifications" to postNotifications
                        )
                    )
                }

                "requestPermissions" -> {
                    val permissionsToRequest = mutableListOf<String>()

                    if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.RECEIVE_SMS
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        permissionsToRequest.add(Manifest.permission.RECEIVE_SMS)
                    }

                    if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.READ_SMS
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        permissionsToRequest.add(Manifest.permission.READ_SMS)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ContextCompat.checkSelfPermission(
                                this,
                                Manifest.permission.POST_NOTIFICATIONS
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            permissionsToRequest.add(Manifest.permission.POST_NOTIFICATIONS)
                        }
                    }

                    if (permissionsToRequest.isEmpty()) {
                        result.success(true)
                    } else {
                        pendingResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            permissionsToRequest.toTypedArray(),
                            PERMISSION_REQUEST_CODE
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val txMap = extractTransactionFromIntent(intent)
        if (txMap != null) {
            intent.removeExtra(NotificationHelper.EXTRA_IS_DETECTED_EXPENSE)
            NotificationHelper.clearPendingTransaction(applicationContext)
            methodChannel?.invokeMethod("onTransactionDetected", txMap)
        }
    }

    private fun extractTransactionFromIntent(targetIntent: Intent?): Map<String, Any?>? {
        if (targetIntent == null) return null
        val isDetected = targetIntent.getBooleanExtra(NotificationHelper.EXTRA_IS_DETECTED_EXPENSE, false)
        if (!isDetected) return null

        return mapOf(
            NotificationHelper.EXTRA_AMOUNT to targetIntent.getDoubleExtra(NotificationHelper.EXTRA_AMOUNT, 0.0),
            NotificationHelper.EXTRA_MERCHANT to targetIntent.getStringExtra(NotificationHelper.EXTRA_MERCHANT),
            NotificationHelper.EXTRA_PAYMENT_METHOD to targetIntent.getStringExtra(NotificationHelper.EXTRA_PAYMENT_METHOD),
            NotificationHelper.EXTRA_TRANSACTION_ID to targetIntent.getStringExtra(NotificationHelper.EXTRA_TRANSACTION_ID),
            NotificationHelper.EXTRA_TRANSACTION_DATE to targetIntent.getLongExtra(
                NotificationHelper.EXTRA_TRANSACTION_DATE,
                System.currentTimeMillis()
            ),
            NotificationHelper.EXTRA_RAW_BODY to targetIntent.getStringExtra(NotificationHelper.EXTRA_RAW_BODY),
            NotificationHelper.EXTRA_SENDER to targetIntent.getStringExtra(NotificationHelper.EXTRA_SENDER)
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingResult?.success(allGranted)
            pendingResult = null
        }
    }

    override fun onDestroy() {
        if (currentInstance?.get() == this) {
            currentInstance = null
            methodChannel = null
        }
        super.onDestroy()
    }
}
