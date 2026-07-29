import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/mileage_provider.dart';

class AddMileageSheet extends StatefulWidget {
  const AddMileageSheet({super.key});

  @override
  State<AddMileageSheet> createState() => _AddMileageSheetState();
}

class _AddMileageSheetState extends State<AddMileageSheet> {
  final _odoCtrl = TextEditingController();
  final _fuelCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _odoCtrl.dispose();
    _fuelCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final odo = double.tryParse(_odoCtrl.text.trim());
    final fuel = double.tryParse(_fuelCtrl.text.trim());
    final price = double.tryParse(_priceCtrl.text.trim());

    if (odo == null || fuel == null || price == null) {
      setState(() => _err = 'Please fill all fields');
      return;
    }

    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      await context.read<MileageProvider>().addRecord(
            odometerReading: odo,
            fuelLiters: fuel,
            pricePerLiter: price,
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

    return SingleChildScrollView(
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
            'New Fuel Record',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          const _SheetLabel('ODOMETER READING (KM)'),
          const SizedBox(height: 8),
          _SheetField(
            controller: _odoCtrl,
            hint: 'Current total km',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 18),
          const _SheetLabel('FUEL FILLED (LITERS)'),
          const SizedBox(height: 8),
          _SheetField(
            controller: _fuelCtrl,
            hint: 'Quantity in liters',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 18),
          const _SheetLabel('PRICE PER LITER (₹)'),
          const SizedBox(height: 8),
          _SheetField(
            controller: _priceCtrl,
            hint: 'Current fuel price',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (_err != null) ...[
            const SizedBox(height: 8),
            Text(
              _err!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
                        'Add Record',
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
