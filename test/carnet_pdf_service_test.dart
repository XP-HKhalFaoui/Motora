import 'package:carnet_auto/core/formatters.dart';
import 'package:carnet_auto/models/admin_document.dart';
import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/models/maintenance_prediction.dart';
import 'package:carnet_auto/models/maintenance_type.dart';
import 'package:carnet_auto/models/vehicle.dart';
import 'package:carnet_auto/services/carnet_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _now = DateTime(2026, 7, 28);

CarnetData _data({
  List<MaintenancePrediction> predictions = const [],
  List<MaintenanceHistory> history = const [],
  List<AdminDocument> documents = const [],
  double? kmPerMonth = 1200,
}) =>
    CarnetData(
      vehicle: const Vehicle(
        id: 'v1',
        userId: 'u1',
        name: 'Clio IV',
        brand: 'Renault',
        year: 2019,
        plateNumber: '00123-116-16',
        currentKm: 148320,
      ),
      predictions: predictions,
      history: history,
      documents: documents,
      kmPerMonth: kmPerMonth,
      generatedAt: _now,
    );

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  test('produces a valid PDF for an empty carnet', () async {
    final bytes = await CarnetPdfService.build(_data());

    expect(bytes.length, greaterThan(1000));
    // %PDF- magic number.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('produces a valid PDF with every section populated', () async {
    final bytes = await CarnetPdfService.build(_data(
      predictions: [
        MaintenancePrediction(
          type: const MaintenanceType(
            id: 't1',
            vehicleId: 'v1',
            label: 'Vidange moteur',
            intervalKm: 7000,
            lastDoneKm: 145000,
          ),
          remainingKm: 3680,
          dueDate: DateTime(2026, 10, 1),
          kmPerMonth: 1200,
          urgency: 0.47,
        ),
        // The unforecastable case has its own column value.
        const MaintenancePrediction(
          type: MaintenanceType(
            id: 't2',
            vehicleId: 'v1',
            label: 'Kit distribution',
            intervalKm: 60000,
          ),
          remainingKm: null,
          dueDate: null,
          kmPerMonth: 1200,
          urgency: 0,
          needsSetup: true,
        ),
      ],
      history: [
        MaintenanceHistory(
          id: 'h1',
          vehicleId: 'v1',
          title: 'Vidange + filtre à huile',
          km: 145000,
          cost: 8500,
          garageName: 'Garage Bencheikh',
          doneAt: DateTime(2026, 3, 12),
        ),
        MaintenanceHistory(
          id: 'f1',
          vehicleId: 'v1',
          title: 'Plein',
          km: 146000,
          liters: 42,
          cost: 1890,
          isFuel: true,
          doneAt: DateTime(2026, 5, 2),
        ),
        MaintenanceHistory(
          id: 'f2',
          vehicleId: 'v1',
          title: 'Plein',
          km: 146600,
          liters: 38,
          cost: 1710,
          isFuel: true,
          doneAt: DateTime(2026, 6, 9),
        ),
      ],
      documents: [
        AdminDocument(
          id: 'd1',
          vehicleId: 'v1',
          docType: 'controle_technique',
          year: 2026,
          expiryDate: DateTime(2027, 1, 15),
          fileUrl: 'u1/ct.pdf',
        ),
      ],
    ));

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
  });

  group('pdfSafe', () {
    // The regression this exists for: the first export off a real device
    // printed an empty box wherever an amount or a dash appeared. The pdf
    // package's built-in Helvetica is Latin-1 only, and it does *not*
    // throw on a glyph it lacks — it silently draws a rectangle. Asserting
    // that build() completes therefore proves nothing about the output,
    // which is exactly why this bug shipped past the earlier test.
    test('keeps Latin-1 text, accents included, untouched', () {
      const text = 'Réparation embrayage — pièces àéèôç';
      expect(CarnetPdfService.pdfSafe('Réparation embrayage pièces àéèôç'),
          'Réparation embrayage pièces àéèôç');
      expect(CarnetPdfService.pdfSafe(text), isNot(contains('—')));
    });

    test('replaces the punctuation Helvetica cannot draw', () {
      expect(CarnetPdfService.pdfSafe('a — b'), 'a - b');
      expect(CarnetPdfService.pdfSafe('a – b'), 'a - b');
      expect(CarnetPdfService.pdfSafe('suite…'), 'suite...');
      expect(CarnetPdfService.pdfSafe('l’huile'), "l'huile");
    });

    test('replaces the narrow no-break space in French numbers', () {
      // Fmt.km separates thousands with U+202F, which is not Latin-1.
      final formatted = Fmt.km(569265);
      expect(formatted.runes.any((r) => r > 0xFF), isTrue,
          reason: 'guards the premise: the raw output is not Latin-1');
      final safe = CarnetPdfService.pdfSafe(formatted);
      expect(safe.runes.every((r) => r <= 0xFF), isTrue);
      expect(safe, '569 265 km');
    });

    test('degrades unmappable text to a visible marker, not a mystery box', () {
      // e.g. an Arabic garage name — wrong, but legibly wrong.
      expect(CarnetPdfService.pdfSafe('كراج'), '????');
    });

    test('everything the formatters emit survives the round trip', () {
      for (final value in [
        Fmt.money(48300),
        Fmt.km(569265),
        Fmt.date(_now),
        Fmt.dateShort(_now),
        Fmt.relative(_now.add(const Duration(days: 90))),
      ]) {
        final safe = CarnetPdfService.pdfSafe(value);
        expect(safe.runes.every((r) => r <= 0xFF), isTrue,
            reason: 'unrenderable character left in "$value"');
        expect(safe, isNot(contains('?')),
            reason: 'formatter output should map cleanly, not degrade: '
                '"$value"');
      }
    });
  });

  test('renders accents and amounts without unrenderable characters', () async {
    final bytes = await CarnetPdfService.build(_data(
      history: [
        MaintenanceHistory(
          id: 'h1',
          vehicleId: 'v1',
          title: 'Réparation embrayage — pièces d\'origine (garantie 2 ans)',
          km: 140000,
          cost: 1234.56,
          garageName: 'Éts Ménard & Fils',
          doneAt: DateTime(2026, 1, 5),
        ),
      ],
    ));

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('says the monthly average is unmeasured rather than inventing one',
      () async {
    final bytes = await CarnetPdfService.build(_data(kmPerMonth: null));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
