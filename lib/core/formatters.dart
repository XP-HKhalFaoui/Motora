import 'package:intl/intl.dart';

/// Locale-aware formatting helpers (French).
class Fmt {
  static final _date = DateFormat('d MMM yyyy', 'fr_FR');
  static final _dateShort = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final _km = NumberFormat.decimalPattern('fr_FR');
  static final _money = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

  static String date(DateTime? d) => d == null ? '—' : _date.format(d);
  static String dateShort(DateTime? d) => d == null ? '—' : _dateShort.format(d);
  static String km(num? v) => v == null ? '—' : '${_km.format(v)} km';
  static String money(num? v) => v == null ? '—' : _money.format(v);

  /// "dans 2 mois", "dans 12 jours", "en retard" for a future/past date.
  static String relative(DateTime? target) {
    if (target == null) return '—';
    final now = DateTime.now();
    final diff = target.difference(DateTime(now.year, now.month, now.day));
    final days = diff.inDays;
    if (days < 0) return 'en retard de ${-days} j';
    if (days == 0) return "aujourd'hui";
    if (days < 45) return 'dans $days j';
    final months = (days / 30).round();
    return 'dans $months mois';
  }
}
