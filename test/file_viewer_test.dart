import 'package:carnet_auto/core/constants.dart';
import 'package:carnet_auto/screens/files/file_viewer_screen.dart';
import 'package:flutter_test/flutter_test.dart';

FileViewerScreen _viewer(String reference) => FileViewerScreen(
      bucket: Buckets.invoices,
      reference: reference,
      title: 'Facture',
    );

void main() {
  group('FileViewerScreen image detection', () {
    test('treats common image extensions as viewable inline', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'heic', 'gif']) {
        expect(_viewer('uid/facture.$ext').isImage, isTrue, reason: ext);
      }
    });

    test('is case-insensitive', () {
      expect(_viewer('uid/SCAN.JPG').isImage, isTrue);
    });

    test('hands a PDF to the system viewer instead', () {
      expect(_viewer('uid/facture.pdf').isImage, isFalse);
    });

    test('reads the extension through a legacy signed URL', () {
      const url = 'https://xyz.supabase.co/storage/v1/object/sign/'
          'invoices/uid/facture.pdf?token=abc';
      expect(_viewer(url).isImage, isFalse);
    });

    test('falls back to not-an-image when there is no extension', () {
      expect(_viewer('uid/facture').isImage, isFalse);
    });
  });
}
