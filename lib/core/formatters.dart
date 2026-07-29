import 'package:intl/intl.dart';

/// Locale-aware formatting helpers (French).
class Fmt {
  static final _date = DateFormat('d MMM yyyy', 'fr_FR');
  static final _dateShort = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final _monthYear = DateFormat('MMM yyyy', 'fr_FR');
  static final _monthShort = DateFormat('MM/yy', 'fr_FR');
  static final _dayMonth = DateFormat('d MMM', 'fr_FR');
  static final _monthHeader = DateFormat('MMMM yyyy', 'fr_FR');
  static final _km = NumberFormat.decimalPattern('fr_FR');

  /// Algerian dinar. The app is used in Algeria — plates, vignette, carte
  /// grise, and fuel priced around 30 DA/L — but this used to print € on
  /// every amount, so a 1 000 DA tank read as 1 000 €.
  ///
  /// "DA" rather than "د.ج" on purpose: it stays inside Latin-1, which the
  /// PDF export's built-in font can actually render.
  static final _money =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'DA', decimalDigits: 2);

  static String date(DateTime? d) => d == null ? '—' : _date.format(d);
  static String dateShort(DateTime? d) =>
      d == null ? '—' : _dateShort.format(d);

  /// "22 mai" — a timeline row already sits under its month header, so
  /// repeating the year on every line is noise.
  static String dayMonth(DateTime? d) => d == null ? '—' : _dayMonth.format(d);

  /// "MAI 2026" — the section header a long timeline is navigated by.
  static String monthHeader(DateTime? d) =>
      d == null ? '—' : _monthHeader.format(d).toUpperCase();

  /// "07/26" — compact enough for a chart axis with a year of bars.
  static String monthShort(DateTime? d) =>
      d == null ? '—' : _monthShort.format(d);

  static String monthYear(DateTime? d) =>
      d == null ? '—' : _monthYear.format(d);
  static String km(num? v) => v == null ? '—' : '${_km.format(v)} km';
  static String money(num? v) => v == null ? '—' : _money.format(v);

  /// Currency suffix for input fields, so a form label can never drift
  /// from what [money] actually prints.
  static String get currencySuffix => _money.currencySymbol;

  /// `yyyy-MM-dd` for Postgres `date` columns.
  ///
  /// The calendar day is taken from the *local* date. Sending a full
  /// ISO-8601 timestamp instead lets Postgres truncate it after a UTC
  /// conversion, so an entry made at 23:30 local lands on the next day.
  static String? isoDate(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

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
