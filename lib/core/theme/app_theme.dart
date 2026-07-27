import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.textPrimary,
        surface: AppColors.cardBg,
      ),
      useMaterial3: true,
      // Add more theme configurations here if needed
    );
  }
}
