import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class IconBubble extends StatelessWidget {
  final double cx, cy;
  final IconData icon;
  const IconBubble({super.key, required this.cx, required this.cy, required this.icon});

  @override
  Widget build(BuildContext context) {
    const r = 26.0;
    return Positioned(
      left: cx - r,
      top: cy - r,
      child: Container(
        width: r * 2,
        height: r * 2,
        decoration: const BoxDecoration(color: AppColors.iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}
