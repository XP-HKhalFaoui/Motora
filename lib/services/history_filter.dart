import '../models/maintenance_history.dart';

enum HistoryKind { all, maintenance, fuel, expense }

enum HistoryPeriod { all, last12Months, thisYear }

/// Search + filter criteria for the history timeline.
///
/// Pure and self-contained so the matching rules — accent-insensitive
/// search in particular — can be tested without a widget tree.
class HistoryFilter {
  const HistoryFilter({
    this.query = '',
    this.kind = HistoryKind.all,
    this.garageName,
    this.period = HistoryPeriod.all,
  });

  final String query;
  final HistoryKind kind;
  final String? garageName;
  final HistoryPeriod period;

  bool get isEmpty =>
      query.trim().isEmpty &&
      kind == HistoryKind.all &&
      garageName == null &&
      period == HistoryPeriod.all;

  HistoryFilter copyWith({
    String? query,
    HistoryKind? kind,
    Object? garageName = _unset,
    HistoryPeriod? period,
  }) =>
      HistoryFilter(
        query: query ?? this.query,
        kind: kind ?? this.kind,
        garageName:
            garageName == _unset ? this.garageName : garageName as String?,
        period: period ?? this.period,
      );

  static const _unset = Object();

  List<MaintenanceHistory> apply(
    List<MaintenanceHistory> items, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final needle = _normalize(query);

    return items.where((h) {
      switch (kind) {
        case HistoryKind.maintenance:
          if (!h.isMaintenance) return false;
        case HistoryKind.fuel:
          if (!h.isFuel) return false;
        case HistoryKind.expense:
          if (!h.isExpense) return false;
        case HistoryKind.all:
          break;
      }

      if (garageName != null && h.garageName != garageName) return false;

      switch (period) {
        case HistoryPeriod.last12Months:
          if (h.doneAt.isBefore(DateTime(ref.year - 1, ref.month, ref.day))) {
            return false;
          }
        case HistoryPeriod.thisYear:
          if (h.doneAt.year != ref.year) return false;
        case HistoryPeriod.all:
          break;
      }

      if (needle.isEmpty) return true;
      final haystack = _normalize([
        h.title,
        h.garageName ?? '',
        h.description ?? '',
        h.km?.toString() ?? '',
      ].join(' '));
      return haystack.contains(needle);
    }).toList();
  }

  /// Lowercase and strip French accents, so "reparation" finds
  /// "Réparation" — nobody types accents into a search box.
  static String _normalize(String input) {
    const from = 'àâäáãåéèêëíìîïóòôöõúùûüçñ';
    const to = 'aaaaaaeeeeiiiiooooouuuucn';
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString().trim();
  }
}
