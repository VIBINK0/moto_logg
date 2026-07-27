String formatCurrency(double v) {
  final s = v.toStringAsFixed(0);
  if (s.length > 3) {
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
  return s;
}
