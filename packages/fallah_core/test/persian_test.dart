import 'package:fallah_core/fallah_core.dart';
import 'package:test/test.dart';

void main() {
  test('toPersianDigits converts Latin and Arabic-Indic digits', () {
    expect(toPersianDigits('Ab 0123456789 ٠١٢'), 'Ab ۰۱۲۳۴۵۶۷۸۹ ۰۱۲');
  });

  test('formatJalali converts a Gregorian date', () {
    final d = DateTime(2026, 10, 18, 14, 5);
    expect(formatJalali(d, persianDigits: false), '1405/07/26');
    expect(formatJalali(d), '۱۴۰۵/۰۷/۲۶');
    expect(
      formatJalali(d, withTime: true, persianDigits: false),
      '1405/07/26 14:05',
    );
  });

  test('formatJalaliLong uses the month name', () {
    expect(formatJalaliLong(DateTime(2026, 10, 18)), '۲۶ مهر ۱۴۰۵');
    expect(
      formatJalaliLong(DateTime(2026, 3, 21), persianDigits: false),
      '1 فروردین 1405',
    );
  });

  test('leap-year boundary: 1403 has 30 Esfand', () {
    // 1403/12/30 = 2025-03-20.
    expect(
      formatJalali(DateTime(2025, 3, 20), persianDigits: false),
      '1403/12/30',
    );
  });
}
