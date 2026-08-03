import '../core/constants.dart';
import '../models/admin_document.dart';
import '../models/maintenance_prediction.dart';
import 'next_due_service.dart';

/// Due screen status band. Unlike [MaintenancePrediction.urgency] (a
/// proportional fraction of the interval consumed), this is the Aurora
/// spec's own absolute-threshold scheme: "urgent ≤ 14 days or ≤ 1 000 km,
/// à surveiller ≤ 60 days or ≤ 5 000 km, OK beyond". [toConfigure] is a
/// maintenance type with no interval set up yet — it never applies to
/// documents, which always carry a real expiry date.
enum DueStatus { urgent, watch, ok, toConfigure }

/// One row in the Due screen's unified list — a maintenance forecast or a
/// document, tagged with its computed [DueStatus] and a 0..1 [progress]
/// for the hero card's bar.
class DueEntry {
  const DueEntry({
    required this.id,
    required this.isMaintenance,
    required this.status,
    required this.label,
    required this.remainingDays,
    required this.remainingKm,
    required this.dueDate,
    required this.progress,
    this.prediction,
    this.document,
  });

  /// `maint_<typeId>` or `doc_<documentId>` — also the key
  /// [PostponeNotifier] stores "Reporter" overrides under.
  final String id;

  final bool isMaintenance;
  final DueStatus status;
  final String label;
  final int? remainingDays;
  final int? remainingKm;
  final DateTime? dueDate;
  final double progress;

  final MaintenancePrediction? prediction;
  final AdminDocument? document;

  /// Ascending: soonest/most overdue first.
  int get sortKey => remainingDays ?? remainingKm ?? (1 << 30);
}

class DueBoard {
  const DueBoard({required this.entries, required this.counts});
  final List<DueEntry> entries;
  final Map<DueStatus, int> counts;

  int countOf(DueStatus s) => counts[s] ?? 0;
}

class DueStatusService {
  DueStatusService._();

  static const urgentDays = 14;
  static const watchDays = 60;

  /// Builds the full unified board from real data: every maintenance
  /// prediction plus every document, each classified and given a
  /// hero-bar progress figure. [isPostponed] looks up whether a "Reporter"
  /// override is still active for a given entry id.
  static DueBoard build({
    required List<MaintenancePrediction> predictions,
    required List<AdminDocument> documents,
    required int kmAlertThreshold,
    required int daysAlertThreshold,
    required bool Function(String id) isPostponed,
  }) {
    final entries = <DueEntry>[];

    for (final p in predictions) {
      final id = 'maint_${p.type.id}';
      final status = p.needsSetup
          ? DueStatus.toConfigure
          : _applyPostpone(
              _classify(
                remainingDays: p.dueDate?.difference(DateTime.now()).inDays,
                remainingKm: p.remainingKm,
                urgentKm: kmAlertThreshold,
                watchKm: kmAlertThreshold * 5,
              ),
              isPostponed(id),
            );
      entries.add(DueEntry(
        id: id,
        isMaintenance: true,
        status: status,
        label: p.type.label,
        remainingDays: p.dueDate?.difference(DateTime.now()).inDays,
        remainingKm: p.remainingKm,
        dueDate: p.dueDate,
        progress: p.progress,
        prediction: p,
      ));
    }

    for (final d in documents) {
      final id = 'doc_${d.id}';
      final status = _applyPostpone(
        _classify(remainingDays: d.daysToExpiry),
        isPostponed(id),
      );
      entries.add(DueEntry(
        id: id,
        isMaintenance: false,
        status: status,
        label: '${DocTypes.label(d.docType)} ${d.year}',
        remainingDays: d.daysToExpiry,
        remainingKm: null,
        dueDate: d.expiryDate,
        progress: NextDueService.documentUrgency(d, daysAlertThreshold).clamp(0.0, 1.0),
        document: d,
      ));
    }

    final counts = <DueStatus, int>{for (final s in DueStatus.values) s: 0};
    for (final e in entries) {
      counts[e.status] = (counts[e.status] ?? 0) + 1;
    }
    return DueBoard(entries: entries, counts: counts);
  }

  static DueStatus _applyPostpone(DueStatus status, bool postponed) =>
      postponed && status == DueStatus.urgent ? DueStatus.watch : status;

  static DueStatus _classify({
    required int? remainingDays,
    int? remainingKm,
    int? urgentKm,
    int? watchKm,
  }) {
    if ((remainingDays != null && remainingDays <= urgentDays) ||
        (remainingKm != null && urgentKm != null && remainingKm <= urgentKm)) {
      return DueStatus.urgent;
    }
    if ((remainingDays != null && remainingDays <= watchDays) ||
        (remainingKm != null && watchKm != null && remainingKm <= watchKm)) {
      return DueStatus.watch;
    }
    return DueStatus.ok;
  }
}
