import 'package:shamsi_date/shamsi_date.dart';

/// Replaces Latin (0-9) and Arabic-Indic (٠-٩) digits with Persian ones (۰-۹).
String toPersianDigits(String input) {
  final out = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= 0x30 && unit <= 0x39) {
      out.writeCharCode(unit - 0x30 + 0x06F0);
    } else if (unit >= 0x0660 && unit <= 0x0669) {
      out.writeCharCode(unit - 0x0660 + 0x06F0);
    } else {
      out.writeCharCode(unit);
    }
  }
  return out.toString();
}

/// Persian month names, index 0 = Farvardin.
const jalaliMonthNames = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// Formats [date] (converted to local time) as a Jalali date, e.g.
/// `1405/07/26` or `1405/07/26 14:05` with [withTime].
///
/// The API sends and receives Gregorian ISO-8601; use this for display only.
String formatJalali(
  DateTime date, {
  bool withTime = false,
  bool persianDigits = true,
  String separator = '/',
}) {
  final local = date.toLocal();
  final j = Jalali.fromDateTime(local);
  final day = '${j.year}$separator${_two(j.month)}$separator${_two(j.day)}';
  final text =
      withTime ? '$day ${_two(local.hour)}:${_two(local.minute)}' : day;
  return persianDigits ? toPersianDigits(text) : text;
}

/// Long form, e.g. `۲۶ مهر ۱۴۰۵`.
String formatJalaliLong(DateTime date, {bool persianDigits = true}) {
  final j = Jalali.fromDateTime(date.toLocal());
  final text = '${j.day} ${jalaliMonthNames[j.month - 1]} ${j.year}';
  return persianDigits ? toPersianDigits(text) : text;
}
