import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});
  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  ExpenseCategory _cat = ExpenseCategory.fuel;
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.textPrimary,
            onPrimary: Colors.black,
            surface: AppColors.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amtCtrl.text.trim());
    if (amt == null || amt <= 0) {
      setState(() => _err = 'Enter a valid amount');
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await context.read<ExpenseProvider>().add(
        category: _cat,
        amount: amt,
        date: _date,
        notes: _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _err = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, inset + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Add Expense',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          const _SheetLabel('CATEGORY'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.values.map((c) {
              final sel = c == _cat;
              return GestureDetector(
                onTap: () => setState(() => _cat = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.textPrimary : AppColors.iconBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.textPrimary : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.iconData,
                        size: 14,
                        color: sel ? Colors.black : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.label,
                        style: TextStyle(
                          color: sel ? Colors.black : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const _SheetLabel('AMOUNT (₹)'),
          const SizedBox(height: 8),
          _SheetField(
            controller: _amtCtrl,
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 14),
          const _SheetLabel('DATE'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_date.day.toString().padLeft(2, '0')} / '
                    '${_date.month.toString().padLeft(2, '0')} / '
                    '${_date.year}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _SheetLabel('NOTES (OPTIONAL)'),
          const SizedBox(height: 8),
          _SheetField(
            controller: _noteCtrl,
            hint: 'e.g. Petrol at HP station',
            maxLines: 2,
          ),
          if (_err != null) ...[
            const SizedBox(height: 8),
            Text(
              _err!,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loading ? null : _save,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Save Expense',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textDim,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
    ),
  );
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  const _SheetField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textDim),
        filled: true,
        fillColor: AppColors.iconBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF555555), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
