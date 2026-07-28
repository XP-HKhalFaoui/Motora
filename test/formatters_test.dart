import 'package:carnet_auto/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fmt.isoDate', () {
    test('returns null for a null date', () {
      expect(Fmt.isoDate(null), isNull);
    });

    test('pads month and day', () {
      expect(Fmt.isoDate(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('keeps the local calendar day for a late-evening entry', () {
      // The regression: toIso8601String() on a local DateTime hands
      // Postgres a timestamp it truncates after converting, so an entry
      // made at 23:30 could land on the following day east of UTC.
      expect(Fmt.isoDate(DateTime(2026, 7, 28, 23, 30)), '2026-07-28');
      expect(Fmt.isoDate(DateTime(2026, 7, 28, 0, 15)), '2026-07-28');
    });
  });
}
