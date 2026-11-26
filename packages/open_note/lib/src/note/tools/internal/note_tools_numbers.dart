// Internal to the tools module; not exported from the barrel.

/// [value] clamped into `[min, max]`, or [fallback] when [value] is NaN or
/// infinite.
double noteClampOr(
  double value, {
  required double min,
  required double max,
  required double fallback,
}) {
  if (!value.isFinite) return fallback;

  return value.clamp(min, max);
}

/// [value] with at most two decimals and no trailing zeros: `3`, `2.5`,
/// `0.35`.
String noteTrimNumber(double value) {
  final fixed = value.toStringAsFixed(2);
  if (!fixed.contains('.')) return fixed;
  final trimmed = fixed.replaceFirst(RegExp(r'0+$'), '');

  return trimmed.endsWith('.')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
