/// Formats a number the way the React UI does: integers print without a
/// trailing ".0" (8.0 -> "8"), fractions keep their decimals (7.5 -> "7.5").
String fmtNum(num v) {
  final d = v.toDouble();
  if (d == d.truncateToDouble()) return d.toInt().toString();
  return d.toString();
}

/// Rounds to one decimal place, mirroring `Math.round(x * 10) / 10`.
double round1(double v) => (v * 10).round() / 10;

String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
