import 'package:carnet_auto/models/admin_document.dart';
import 'package:carnet_auto/models/maintenance_prediction.dart';
import 'package:carnet_auto/models/maintenance_type.dart';
import 'package:carnet_auto/services/next_due_service.dart';
import 'package:flutter_test/flutter_test.dart';

MaintenancePrediction _prediction({
  required double urgency,
  int? remainingKm,
  DateTime? dueDate,
  bool needsSetup = false,
  String label = 'Vidange',
}) =>
    MaintenancePrediction(
      type: MaintenanceType(id: 't1', vehicleId: 'v1', label: label),
      remainingKm: remainingKm,
      dueDate: dueDate,
      kmPerMonth: 1000,
      urgency: urgency,
      needsSetup: needsSetup,
    );

AdminDocument _document({
  required DateTime expiryDate,
  DateTime? issuedDate,
  String docType = 'assurance',
}) =>
    AdminDocument(
      id: 'd1',
      vehicleId: 'v1',
      docType: docType,
      year: 2026,
      issuedDate: issuedDate,
      expiryDate: expiryDate,
    );

void main() {
  group('NextDueService.next', () {
    test('returns null with nothing to forecast', () {
      final result = NextDueService.next(
        predictions: const [],
        documents: const [],
        daysAlertThreshold: 30,
      );
      expect(result, isNull);
    });

    test('ignores predictions still awaiting their anchor', () {
      final result = NextDueService.next(
        predictions: [_prediction(urgency: 0, needsSetup: true)],
        documents: const [],
        daysAlertThreshold: 30,
      );
      expect(result, isNull);
    });

    test('picks the most urgent maintenance prediction when no documents compete',
        () {
      final due = DateTime(2026, 8, 5);
      final result = NextDueService.next(
        predictions: [
          _prediction(urgency: 0.4, label: 'Filtre à air'),
          _prediction(urgency: 0.9, label: 'Vidange', remainingKm: 300, dueDate: due),
        ],
        documents: const [],
        daysAlertThreshold: 30,
      );
      expect(result!.label, 'Vidange');
      expect(result.isMaintenance, isTrue);
      expect(result.remainingKm, 300);
      expect(result.urgency, 0.9);
    });

    // AdminDocument.daysToExpiry reads the real wall clock (no injectable
    // "now"), so these are built off DateTime.now() to stay deterministic
    // regardless of when the suite runs.
    test('a document can outrank a less urgent maintenance prediction', () {
      final today = DateTime.now();
      // Expires in 2 days out of a 365-day span -> ~99% elapsed.
      final result = NextDueService.next(
        predictions: [_prediction(urgency: 0.2)],
        documents: [
          _document(
            issuedDate: today.subtract(const Duration(days: 363)),
            expiryDate: today.add(const Duration(days: 2)),
          ),
        ],
        daysAlertThreshold: 30,
      );
      expect(result!.isMaintenance, isFalse);
      expect(result.urgency, greaterThan(0.9));
    });

    test('document without an issued date falls back to the alert window as the interval',
        () {
      final today = DateTime.now();
      // At the alert threshold -> right at the start of the assumed
      // interval (2x the threshold), so ~50% elapsed.
      final doc = _document(expiryDate: today.add(const Duration(days: 30)));
      final result = NextDueService.next(
        predictions: const [],
        documents: [doc],
        daysAlertThreshold: 30,
      );
      expect(result!.urgency, closeTo(0.5, 0.03));
    });

    test('an overdue document reads as urgency >= 1, not clamped away', () {
      final today = DateTime.now();
      final doc = _document(
        issuedDate: today.subtract(const Duration(days: 100)),
        expiryDate: today.subtract(const Duration(days: 5)),
      );
      final result = NextDueService.next(
        predictions: const [],
        documents: [doc],
        daysAlertThreshold: 30,
      );
      expect(result!.urgency, greaterThanOrEqualTo(1.0));
      expect(result.progress, 1.0);
    });
  });
}
