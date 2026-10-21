import 'package:fallah_core/fallah_core.dart';
import 'package:test/test.dart';

void main() {
  test('normalizeDigits converts Persian and Arabic digits', () {
    expect(Validators.normalizeDigits('۰۹۱۲٣'), '09123');
  });

  test('isMobile', () {
    expect(Validators.isMobile('09121234567'), isTrue);
    expect(Validators.isMobile('۰۹۱۲۱۲۳۴۵۶۷'), isTrue);
    expect(Validators.isMobile('9121234567'), isFalse);
    expect(Validators.isMobile('0912123456'), isFalse);
  });

  test('isNationalCode checksum', () {
    expect(Validators.isNationalCode('0499370899'), isTrue);
    expect(Validators.isNationalCode('0499370890'), isFalse);
    expect(Validators.isNationalCode('1111111111'), isFalse);
    expect(Validators.isNationalCode('123'), isFalse);
  });

  test('isPostalCode', () {
    expect(Validators.isPostalCode('1234567890'), isTrue);
    expect(Validators.isPostalCode('12345'), isFalse);
  });
}
