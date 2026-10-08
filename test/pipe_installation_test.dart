import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_scrap_app/services/pipe_installation.dart';

void main() {
  test('unit count accepts Arabic, Persian and Latin keyboard input', () {
    for (final value in ['3', '٣', '۳', ' ٣ ']) {
      expect(parseUnitCount(value), 3);
    }
    expect(parseUnitCount('١٠٠'), 100);
    expect(parseUnitCount('1'), 1);
  });

  test('unit count rejects missing, fractional and out-of-range input', () {
    for (final value in ['', ' ', '0', '٠', '-1', '101', '١٠١', '1.5', 'abc']) {
      expect(parseUnitCount(value), isNull, reason: value);
    }
  });
}
