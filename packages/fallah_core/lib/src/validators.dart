/// Pure, locale-aware input checks (Iran-focused). Each returns `true` when
/// valid; apps map `false` to a localized message.
abstract final class Validators {
  /// Converts Persian (۰-۹) and Arabic-Indic (٠-٩) digits to ASCII.
  static String normalizeDigits(String input) {
    final out = StringBuffer();
    for (final unit in input.runes) {
      if (unit >= 0x06F0 && unit <= 0x06F9) {
        out.writeCharCode(unit - 0x06F0 + 0x30);
      } else if (unit >= 0x0660 && unit <= 0x0669) {
        out.writeCharCode(unit - 0x0660 + 0x30);
      } else {
        out.writeCharCode(unit);
      }
    }
    return out.toString();
  }

  /// Iranian mobile number, e.g. `09121234567`.
  static bool isMobile(String value) =>
      RegExp(r'^09\d{9}$').hasMatch(normalizeDigits(value.trim()));

  /// Iranian national code (10 digits with checksum).
  static bool isNationalCode(String value) {
    final v = normalizeDigits(value.trim());
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return false;
    if (RegExp(r'^(\d)\1{9}$').hasMatch(v)) return false;
    final d = v.codeUnits.map((c) => c - 0x30).toList();
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += d[i] * (10 - i);
    }
    final r = sum % 11;
    return d[9] == (r < 2 ? r : 11 - r);
  }

  /// Iranian postal code: 10 digits (format check only).
  static bool isPostalCode(String value) =>
      RegExp(r'^\d{10}$').hasMatch(normalizeDigits(value.trim()));

  static bool isNotBlank(String? value) =>
      value != null && value.trim().isNotEmpty;
}
