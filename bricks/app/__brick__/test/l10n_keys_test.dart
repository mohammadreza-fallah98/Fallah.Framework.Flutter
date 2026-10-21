import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>)
        .keys
        .where((k) => !k.startsWith('@'))
        .toSet();

void main() {
  test('app_fa.arb and app_en.arb define the same keys', () {
    expect(_keys('lib/l10n/app_en.arb'), _keys('lib/l10n/app_fa.arb'));
  });
}
