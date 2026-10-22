package com.example.expanse_tracker

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import java.util.Date

class QuickLogActivity : Activity() {

    companion object {
        private const val TAG = "QuickLogActivity"
        const val CATEGORY_FUEL = "fuel"
        const val CATEGORY_SERVICE = "service"
        const val CATEGORY_ACCESSORIES = "accessories"
        const val CATEGORY_MODIFICATIONS = "modifications"
    }

    private var selectedCategory: String = CATEGORY_FUEL

    private lateinit var etQuickInput: EditText
    private lateinit var tvParsePreview: TextView
    private lateinit var btnSave: FrameLayout
    private lateinit var ivUploadIcon: ImageView
    private lateinit var pbUploadLoading: ProgressBar
    private lateinit var btnClose: TextView

    private lateinit var btnCatFuel: TextView
    private lateinit var btnCatService: TextView
    private lateinit var btnCatAccessories: TextView
    private lateinit var btnCatModifications: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_quick_log)

        initViews()
        setupCategorySelection()
        setupInputParsing()
        setupActions()
        autoFocusInput()
    }

    private fun initViews() {
        etQuickInput = findViewById(R.id.et_quick_input)
        tvParsePreview = findViewById(R.id.tv_parse_preview)
        btnSave = findViewById(R.id.btn_save)
        ivUploadIcon = findViewById(R.id.iv_upload_icon)
        pbUploadLoading = findViewById(R.id.pb_upload_loading)
        btnClose = findViewById(R.id.btn_close)

        btnCatFuel = findViewById(R.id.btn_cat_fuel)
        btnCatService = findViewById(R.id.btn_cat_service)
        btnCatAccessories = findViewById(R.id.btn_cat_accessories)
        btnCatModifications = findViewById(R.id.btn_cat_modifications)

        // Dismiss when tapping outside the card
        findViewById<FrameLayout>(R.id.root_quick_log).setOnClickListener {
            hideKeyboard()
            finish()
        }

        // Prevent dismiss when tapping inside the card
        findViewById<View>(R.id.card_dialog).setOnClickListener {
            // consume touch event
        }
    }

    private fun setupCategorySelection() {
        val categories = listOf(
            Triple(btnCatFuel, CATEGORY_FUEL, "⛽ Fuel"),
            Triple(btnCatService, CATEGORY_SERVICE, "🔧 Service"),
            Triple(btnCatAccessories, CATEGORY_ACCESSORIES, "🪖 Acc"),
            Triple(btnCatModifications, CATEGORY_MODIFICATIONS, "⚡ Mods")
        )

        for ((view, categoryKey, _) in categories) {
            view.setOnClickListener {
                selectedCategory = categoryKey
                updateCategoryPills()
            }
        }

        updateCategoryPills()
    }

    private fun updateCategoryPills() {
        val pills = listOf(
            Pair(btnCatFuel, CATEGORY_FUEL),
            Pair(btnCatService, CATEGORY_SERVICE),
            Pair(btnCatAccessories, CATEGORY_ACCESSORIES),
            Pair(btnCatModifications, CATEGORY_MODIFICATIONS)
        )

        for ((pill, key) in pills) {
            val isSelected = (key == selectedCategory)
            if (isSelected) {
                pill.setBackgroundResource(R.drawable.bg_chip_selected)
                pill.setTextColor(0xFF000000.toInt())
            } else {
                pill.setBackgroundResource(R.drawable.bg_chip_unselected)
                pill.setTextColor(0xFFD1D1D6.toInt())
            }
        }
    }

    private fun setupInputParsing() {
        etQuickInput.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                val (amount, note) = parseInput(s?.toString() ?: "")
                if (amount != null) {
                    val formatted = if (amount % 1.0 == 0.0) {
                        amount.toInt().toString()
                    } else {
                        String.format("%.2f", amount)
                    }

                    if (!note.isNullOrBlank()) {
                        tvParsePreview.text = "₹$formatted  •  Note: $note"
                        tvParsePreview.setTextColor(0xFFFFFFFF.toInt())
                    } else {
                        tvParsePreview.text = "₹$formatted  (add space to add a note)"
                        tvParsePreview.setTextColor(0xFFE5E5EA.toInt())
                    }
                } else {
                    tvParsePreview.text = "e.g. 250 Indian Oil (Amount + Note)"
                    tvParsePreview.setTextColor(0xFF8E8E93.toInt())
                }
            }
        })

        // Save immediately when pressing 'Done' / Enter on the keyboard
        etQuickInput.setOnEditorActionListener { _, actionId, event ->
            if (actionId == EditorInfo.IME_ACTION_DONE ||
                (event != null && event.keyCode == KeyEvent.KEYCODE_ENTER && event.action == KeyEvent.ACTION_DOWN)
            ) {
                saveExpense()
                true
            } else {
                false
            }
        }
    }

    private fun parseInput(rawInput: String): Pair<Double?, String?> {
        val trimmed = rawInput.trim()
            .removePrefix("₹")
            .removePrefix("Rs.")
            .removePrefix("rs.")
            .removePrefix("rs")
            .trim()

        if (trimmed.isEmpty()) return Pair(null, null)

        val parts = trimmed.split("\\s+".toRegex(), limit = 2)
        val amount = parts.getOrNull(0)?.toDoubleOrNull()
        val note = parts.getOrNull(1)?.trim()?.takeIf { it.isNotEmpty() }

        return Pair(amount, note)
    }

    private fun setupActions() {
        btnClose.setOnClickListener {
            hideKeyboard()
            finish()
        }

        btnSave.setOnClickListener {
            saveExpense()
        }
    }

    private fun autoFocusInput() {
        etQuickInput.requestFocus()
        etQuickInput.postDelayed({
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
            imm?.showSoftInput(etQuickInput, InputMethodManager.SHOW_IMPLICIT)
        }, 150)
    }

    private fun hideKeyboard() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        currentFocus?.let { view ->
            imm?.hideSoftInputFromWindow(view.windowToken, 0)
        }
    }

    private fun saveExpense() {
        val (amount, note) = parseInput(etQuickInput.text.toString())

        if (amount == null || amount <= 0.0) {
            Toast.makeText(this, "Please enter an amount (e.g. 250 Indian Oil)", Toast.LENGTH_SHORT).show()
            etQuickInput.requestFocus()
            return
        }

        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser == null) {
            Toast.makeText(this, "⚠️ Please log in to Moto Logg first", Toast.LENGTH_LONG).show()
            finish()
            return
        }

        // Show loading spinner on upload button
        btnSave.isEnabled = false
        ivUploadIcon.visibility = View.GONE
        pbUploadLoading.visibility = View.VISIBLE

        val expenseData = hashMapOf<String, Any?>(
            "category" to selectedCategory,
            "amount" to amount,
            "date" to Timestamp(Date()),
            "notes" to note
        )

        FirebaseFirestore.getInstance()
            .collection("users")
            .document(currentUser.uid)
            .collection("expenses")
            .add(expenseData)
            .addOnSuccessListener {
                triggerHapticFeedback()
                val formattedAmount = if (amount % 1.0 == 0.0) {
                    amount.toInt().toString()
                } else {
                    String.format("%.2f", amount)
                }
                val noteTag = if (!note.isNullOrBlank()) " • $note" else ""
                Toast.makeText(
                    applicationContext,
                    "✅ ₹$formattedAmount saved ($selectedCategory)$noteTag",
                    Toast.LENGTH_SHORT
                ).show()

                hideKeyboard()
                finish()
            }
            .addOnFailureListener { error ->
                Log.e(TAG, "Error saving quick expense", error)
                Toast.makeText(
                    this,
                    "Failed to save: ${error.localizedMessage ?: "Unknown error"}",
                    Toast.LENGTH_LONG
                ).show()
                btnSave.isEnabled = true
                ivUploadIcon.visibility = View.VISIBLE
                pbUploadLoading.visibility = View.GONE
            }
    }

    private fun triggerHapticFeedback() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator?.vibrate(
                    VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
                )
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(
                        VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE)
                    )
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(50)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not trigger haptic feedback", e)
        }
    }
}
