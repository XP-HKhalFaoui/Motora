import '../core/constants.dart';
import '../models/admin_document.dart';
import '../models/maintenance_prediction.dart';

/// The single soonest maintenance échéance or expiring document across a
/// vehicle — the "hero" metric Home is organized around ("never miss a
/// due date"). [urgency] is comparable to
/// [MaintenancePrediction.urgency]: 0 = fresh, 1 = due now, >1 = overdue.
class NextDueItem {
  const NextDueItem({
    required this.label,
    required this.dueDate,
    required this.remainingDays,
    required this.remainingKm,
    required this.urgency,
    required this.isMaintenance,
  });

  final String label;
  final DateTime? dueDate;
  final int? remainingDays;
  final int? remainingKm;
  final double urgency;
  final bool isMaintenance;

  double get progress => urgency.clamp(0.0, 1.0);

  factory NextDueItem.fromMaintenance(MaintenancePrediction p) => NextDueItem(
        label: p.type.label,
        dueDate: p.dueDate,
        remainingDays: p.dueDate?.difference(DateTime.now()).inDays,
        remainingKm: p.remainingKm,
        urgency: p.urgency,
        isMaintenance: true,
      );

  factory NextDueItem.fromDocument(AdminDocument d, int daysAlertThreshold) => NextDueItem(
        label: '${DocTypes.label(d.docType)} ${d.year}',
        dueDate: d.expiryDate,
        remainingDays: d.daysToExpiry,
        remainingKm: null,
        urgency: NextDueService.documentUrgency(d, daysAlertThreshold),
        isMaintenance: false,
      );
}

class NextDueService {
  NextDueService._();

  /// The single most urgent item across maintenance forecasts (excluding
  /// ones still awaiting their anchor) and documents, or null when there
  /// is nothing to show at all.
  static NextDueItem? next({
    required List<MaintenancePrediction> predictions,
    required List<AdminDocument> documents,
    required int daysAlertThreshold,
  }) {
    MaintenancePrediction? bestPred;
    var bestPredUrgency = double.negativeInfinity;
    for (final p in predictions.where((pr) => !pr.needsSetup)) {
      if (p.urgency > bestPredUrgency) {
        bestPredUrgency = p.urgency;
        bestPred = p;
      }
    }

    AdminDocument? bestDoc;
    var bestDocUrgency = double.negativeInfinity;
    for (final d in documents) {
      final u = documentUrgency(d, daysAlertThreshold);
      if (u > bestDocUrgency) {
        bestDocUrgency = u;
        bestDoc = d;
      }
    }

    if (bestPred == null && bestDoc == null) return null;
    if (bestDoc == null) return NextDueItem.fromMaintenance(bestPred!);
    if (bestPred == null) return NextDueItem.fromDocument(bestDoc, daysAlertThreshold);
    return bestPredUrgency >= bestDocUrgency
        ? NextDueItem.fromMaintenance(bestPred)
        : NextDueItem.fromDocument(bestDoc, daysAlertThreshold);
  }

  /// A document has no fixed "interval" the way a maintenance type does.
  /// When [AdminDocument.issuedDate] is on record, elapsed fraction is
  /// measured against the real issued -> expiry span. Otherwise the
  /// user's own alert window doubles as the assumed interval, so a
  /// document just entering the window reads as roughly half-elapsed
  /// rather than fabricating a false 0%.
  ///
  /// Public because [DueStatusService] reuses it for the Due screen's
  /// hero-card progress bar when the hero item is a document.
  static double documentUrgency(AdminDocument d, int daysAlertThreshold) {
    final issued = d.issuedDate;
    final totalDays =
        issued != null ? d.expiryDate.difference(issued).inDays : daysAlertThreshold * 2;
    if (totalDays <= 0) return d.daysToExpiry <= 0 ? 1.0 : 0.0;
    final elapsedDays = totalDays - d.daysToExpiry;
    return elapsedDays / totalDays;
  }
}
