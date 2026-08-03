import 'package:carnet_auto/models/admin_document.dart';
import 'package:carnet_auto/models/maintenance_prediction.dart';
import 'package:carnet_auto/models/maintenance_type.dart';
import 'package:carnet_auto/services/due_status_service.dart';
import 'package:flutter_test/flutter_test.dart';

MaintenancePrediction _prediction({
  int? remainingKm,
  DateTime? dueDate,
  bool needsSetup = false,
  double urgency = 0.5,
  String label = 'Vidange',
  String id = 't1',
}) =>
    MaintenancePrediction(
      type: MaintenanceType(id: id, vehicleId: 'v1', label: label),
      remainingKm: remainingKm,
      dueDate: dueDate,
      kmPerMonth: 1000,
      urgency: urgency,
      needsSetup: needsSetup,
    );

AdminDocument _document({
  required DateTime expiryDate,
  DateTime? issuedDate,
  String id = 'd1',
  String docType = 'assurance',
}) =>
    AdminDocument(
      id: id,
      vehicleId: 'v1',
      docType: docType,
      year: 2026,
      issuedDate: issuedDate,
      expiryDate: expiryDate,
    );

bool _neverPostponed(String id) => false;

void main() {
  final today = DateTime.now();

  group('DueStatusService.build — maintenance', () {
    test('a type with no interval configured is toConfigure, never urgent', () {
      final board = DueStatusService.build(
        predictions: [_prediction(needsSetup: true)],
        documents: const [],
        kmAlertThreshold: 500,
        daysAlertThreshold: 30,
        isPostponed: _neverPostponed,
      );
      expect(board.countOf(DueStatus.toConfigure), 1);
      expect(board.countOf(DueStatus.urgent), 0);
    });

    test('within 14 days is urgent regardless of km', () {
      final board = DueStatusService.build(
        predictions: [_prediction(dueDate: today.add(const Duration(days: 10)), remainingKm: 9000)],
        documents: const [],
        kmAlertThreshold: 500,
        daysAlertThreshold: 30,
        isPostponed: _neverPostponed,
      );
      expect(board.countOf(DueStatus.urgent), 1);
    });

    test('remaining km at or under the user\'s alert threshold is urgent', () {
      final board = DueStatusService.build(
        predictions: [_prediction(dueDate: today.add(const Duration(days: 300)), remainingKm: 400)],
        documents: const [],
        kmAlertThreshold: 500,
        daysAlertThreshold: 30,
        isPostponed: _neverPostponed,
      );
      expect(board.countOf(DueStatus.urgent), 1);
    });

    test('watch band is 5x the km alert threshold', () {
      final justInsideWatch = DueStatusService.build(
        predictions: [_prediction(dueDate: today.add(const Duration(days: 300)), remainingKm: 2500)],
        documents: const [],
        kmAlertThreshold: 500,
        daysAlertThreshold: 30,
        isPostponed: _neverPostponed,
      );
      expect(justInsideWatch.countOf(DueStatus.watch), 1);

      final justOutsideWatch = DueStatusService.build(
        predictions: [_prediction(dueDate: today.add(const Duration(days: 300)), remainingKm: 2501)],
        documents: const [],
        kmAlertThreshold: 500,
        daysAlertThreshold: 30,
        isPostponed: _neverPostponed,
      );
      expect(justOutsideWatch.countOf(DueStatus.ok), 1);
    });

    test('an overdue prediction (negative remaining) is urgent, not ok', () {
      final board = DueStatusService.build(
        predictions: [_prediction(dueDate: today.subtract(const Duration(days: 5)), remainingKm: -200)],
        documents: const [],
        kmAlertThreshold: 500,
        daysAlertThreshold: 30,
        isPostponed: _neverPostponed,
      );
      expect(board.countOf(DueStatus.urgent), 1);
    });

    test('postponing an urgent item pushes it down to watch, not ok', () {
      final board = DueStatusService.build(
        predictions: [_prediction(dueDate: today.add(const Duration(days: 3)), remainingKm: 100)],
        documents: const [],
        kmAlertThreshold: 500,
        daysAlertThreshold: 30,
        isPostponed: (id) => true,
      );
      expect(board.countOf(DueStatus.urgent), 0);
      expect(board.countOf(DueStatus.watch), 1);
    });
  });

  group('DueStatusService.build — documents', () {
    test('a document can never be toConfigure', () {
      final board = DueStatusService.build(
        predictions: const [],
        documents: [_document(expiryDate: today.add(const Duration(days: 400)))],
        kmAlertThreshold: 500,
        daysAlertThreshold: 30,
        isPostponed: _neverPostponed,
      );
      expect(board.countOf(DueStatus.toConfigure), 0);
      expect(board.countOf(DueStatus.ok), 1);
    });

    test('expiring within 14 days is urgent', () {
      final board = DueStatusService.build(
        predictions: const [],
        documents: [_document(expiryDate: today.add(const Duration(days: 5)))],
        kmAlertThreshold: 500,
        daysAlertThreshold: 30,
        isPostponed: _neverPostponed,
      );
      expect(board.countOf(DueStatus.urgent), 1);
    });
  });

  group('DueBoard filtering by kind (screen-level)', () {
    test('entries carry isMaintenance so the segmented filter can split them', () {
      final board = DueStatusService.build(
        predictions: [_prediction(dueDate: today.add(const Duration(days: 5)))],
        documents: [_document(expiryDate: today.add(const Duration(days: 5)))],
        kmAlertThreshold: 500,
        daysAlertThreshold: 30,
        isPostponed: _neverPostponed,
      );
      expect(board.entries.where((e) => e.isMaintenance).length, 1);
      expect(board.entries.where((e) => !e.isMaintenance).length, 1);
    });
  });
}
