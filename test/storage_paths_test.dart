import 'package:carnet_auto/core/storage_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('storagePathFor', () {
    test('passes a plain object path straight through', () {
      expect(
        storagePathFor('invoices', 'abc-uid/history-123.jpg'),
        'abc-uid/history-123.jpg',
      );
    });

    test('is null for nothing stored', () {
      expect(storagePathFor('invoices', null), isNull);
      expect(storagePathFor('invoices', ''), isNull);
    });

    test('recovers the path from a legacy signed URL', () {
      // These were stored with a one-year expiry and never refreshed, so
      // the path has to be dug back out to re-sign them.
      const url = 'https://xyz.supabase.co/storage/v1/object/sign/'
          'vehicle-photos/abc-uid/car-1.jpg'
          '?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      expect(storagePathFor('vehicle-photos', url), 'abc-uid/car-1.jpg');
    });

    test('decodes percent-encoded filenames', () {
      const url = 'https://xyz.supabase.co/storage/v1/object/sign/'
          'invoices/abc-uid/facture%20garage.pdf?token=x';
      expect(storagePathFor('invoices', url), 'abc-uid/facture garage.pdf');
    });

    test('is null when the URL does not belong to the bucket', () {
      const url = 'https://xyz.supabase.co/storage/v1/object/sign/'
          'invoices/abc-uid/facture.pdf?token=x';
      expect(storagePathFor('vehicle-photos', url), isNull);
    });
  });
}
