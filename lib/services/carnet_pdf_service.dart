import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/constants.dart';
import '../core/formatters.dart';
import '../models/admin_document.dart';
import '../models/maintenance_history.dart';
import '../models/maintenance_prediction.dart';
import '../models/vehicle.dart';
import 'fuel_service.dart';

/// Everything one carnet needs, gathered by the caller.
class CarnetData {
  const CarnetData({
    required this.vehicle,
    required this.predictions,
    required this.history,
    required this.documents,
    required this.kmPerMonth,
    required this.generatedAt,
  });

  final Vehicle vehicle;
  final List<MaintenancePrediction> predictions;
  final List<MaintenanceHistory> history;
  final List<AdminDocument> documents;

  /// Measured monthly average, or null when there isn't enough history.
  final double? kmPerMonth;

  /// Passed in rather than read from the clock so the output is
  /// deterministic and testable.
  final DateTime generatedAt;
}

/// Builds the shareable "carnet d'entretien" — the document that gives the
/// whole app its resale value.
class CarnetPdfService {
  /// Rewrites a string into what the PDF's built-in font can actually draw.
  ///
  /// The `pdf` package's standard Helvetica is limited to Latin-1, and it
  /// does **not** throw on a character it lacks — it silently draws an
  /// empty box. Accents are fine (they're Latin-1) but typographic
  /// punctuation is not, and neither was the euro sign: the first export
  /// off a real device came out with a box wherever an amount or a dash
  /// appeared.
  ///
  /// Known substitutes are mapped to their ASCII equivalent; anything else
  /// outside Latin-1 (Arabic garage names, for instance) becomes '?', which
  /// at least reads as missing rather than as a mysterious rectangle.
  static String pdfSafe(String input) {
    const substitutes = {
      0x2014: '-', // — em dash
      0x2013: '-', // – en dash
      0x2026: '...', // … ellipsis
      0x2019: "'", // ’ right single quote
      0x2018: "'", // ‘ left single quote
      0x201C: '"', // “
      0x201D: '"', // ”
      0x202F: ' ', // narrow no-break space — fr_FR thousands separator
      0x2009: ' ', // thin space
      0x20AC: 'EUR', // € euro sign
      0x2192: '->', // → arrow
    };

    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune <= 0xFF) {
        buffer.writeCharCode(rune);
      } else {
        buffer.write(substitutes[rune] ?? '?');
      }
    }
    return buffer.toString();
  }

  static const _ink = PdfColor.fromInt(0xFF16202E);
  static const _muted = PdfColor.fromInt(0xFF5E6B7D);
  static const _accent = PdfColor.fromInt(0xFF2F72E8);
  static const _rule = PdfColor.fromInt(0xFFDDE3EC);
  static const _zebra = PdfColor.fromInt(0xFFF4F6FA);

  static Future<Uint8List> build(CarnetData data) async {
    final doc = pw.Document(
      title: 'Carnet d\'entretien — ${data.vehicle.name}',
      author: 'Motora',
    );

    final repairs = data.history.where((h) => !h.isFuel).toList();
    final fuel = FuelService.analyze(data.history);
    final totalCost = data.history.fold<double>(0, (s, h) => s + (h.cost ?? 0));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        header: (context) =>
            context.pageNumber == 1 ? pw.SizedBox() : _runningHeader(data),
        footer: (context) => _footer(context, data),
        build: (context) => [
          _title(data),
          pw.SizedBox(height: 18),
          _identity(data),
          pw.SizedBox(height: 18),
          _summary(data, totalCost, fuel),
          pw.SizedBox(height: 22),
          _section('Échéances d\'entretien'),
          _schedule(data),
          pw.SizedBox(height: 22),
          _section('Interventions'),
          _interventions(repairs),
          if (fuel.fillUps > 0) ...[
            pw.SizedBox(height: 22),
            _section('Carburant'),
            _fuel(fuel),
          ],
          pw.SizedBox(height: 22),
          _section('Documents administratifs'),
          _documents(data),
        ],
      ),
    );

    return doc.save();
  }

  // ---- blocks ---------------------------------------------------------

  static pw.Widget _title(CarnetData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Carnet d\'entretien',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 2),
            pw.Text(pdfSafe(data.vehicle.name),
                style: const pw.TextStyle(fontSize: 14, color: _muted)),
          ],
        ),
        pw.Text('MOTORA',
            style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _accent,
                letterSpacing: 2)),
      ],
    );
  }

  static pw.Widget _runningHeader(CarnetData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _rule)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(pdfSafe('Carnet d\'entretien — ${data.vehicle.name}'),
              style: const pw.TextStyle(fontSize: 9, color: _muted)),
          pw.Text('MOTORA',
              style: const pw.TextStyle(
                  fontSize: 9, color: _accent, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context, CarnetData data) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(pdfSafe('Généré le ${Fmt.date(data.generatedAt)}'),
              style: const pw.TextStyle(fontSize: 8, color: _muted)),
          pw.Text('${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted)),
        ],
      ),
    );
  }

  static pw.Widget _identity(CarnetData data) {
    final v = data.vehicle;
    final rows = <List<String>>[
      if (v.brand != null) ['Marque', v.brand!],
      if (v.model != null) ['Modèle', v.model!],
      if (v.year != null) ['Année', '${v.year}'],
      if (v.plateNumber != null) ['Immatriculation', v.plateNumber!],
      if (v.purchaseDate != null) ['Achat', Fmt.date(v.purchaseDate)],
    ];
    if (rows.isEmpty) return pw.SizedBox();

    return pw.Wrap(
      spacing: 26,
      runSpacing: 6,
      children: rows
          .map((r) => pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(
                      text: pdfSafe('${r[0]} : '),
                      style: const pw.TextStyle(fontSize: 10, color: _muted)),
                  pw.TextSpan(
                      text: pdfSafe(r[1]),
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: _ink,
                          fontWeight: pw.FontWeight.bold)),
                ]),
              ))
          .toList(),
    );
  }

  static pw.Widget _summary(CarnetData data, double totalCost, FuelStats fuel) {
    final tiles = <List<String>>[
      ['Kilométrage', Fmt.km(data.vehicle.currentKm)],
      [
        'Moyenne mensuelle',
        data.kmPerMonth == null
            ? 'non mesurée'
            : '${data.kmPerMonth!.round()} km',
      ],
      ['Coût total', Fmt.money(totalCost)],
      ['Interventions', '${data.history.where((h) => !h.isFuel).length}'],
    ];

    return pw.Row(
      children: tiles
          .map((t) => pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(right: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _zebra,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(pdfSafe(t[1]),
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      pw.SizedBox(height: 2),
                      pw.Text(pdfSafe(t[0]),
                          style:
                              const pw.TextStyle(fontSize: 8, color: _muted)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  static pw.Widget _section(String label) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _rule)),
      ),
      child: pw.Text(label.toUpperCase(),
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
              letterSpacing: 1)),
    );
  }

  static pw.Widget _schedule(CarnetData data) {
    if (data.predictions.isEmpty) return _empty('Aucune échéance configurée.');

    return _table(
      headers: ['Type', 'Intervalle', 'Dernier entretien', 'État'],
      rows: data.predictions.map((p) {
        final t = p.type;
        final interval = [
          if (t.intervalKm != null) 'tous les ${Fmt.km(t.intervalKm)}',
          if (t.intervalMonths != null) 'tous les ${t.intervalMonths} mois',
        ].join(' · ');
        final lastDone = [
          if (t.lastDoneKm != null) Fmt.km(t.lastDoneKm),
          if (t.lastDoneDate != null) Fmt.date(t.lastDoneDate),
        ].join(' · ');
        final String state;
        if (p.needsSetup) {
          state = 'à configurer';
        } else if (p.remainingKm != null && p.remainingKm! < 0) {
          state = 'dépassé de ${Fmt.km(-p.remainingKm!)}';
        } else if (p.remainingKm != null) {
          state = 'dans ${Fmt.km(p.remainingKm!)}';
        } else {
          state = Fmt.relative(p.dueDate);
        }
        return [t.label, interval, lastDone.isEmpty ? '—' : lastDone, state];
      }).toList(),
    );
  }

  static pw.Widget _interventions(List<MaintenanceHistory> repairs) {
    if (repairs.isEmpty) return _empty('Aucune intervention enregistrée.');

    return _table(
      headers: ['Date', 'Km', 'Intervention', 'Garage', 'Coût'],
      rows: repairs
          .map((h) => [
                Fmt.dateShort(h.doneAt),
                h.km == null ? '—' : Fmt.km(h.km),
                h.title,
                h.garageName ?? '—',
                h.cost == null ? '—' : Fmt.money(h.cost),
              ])
          .toList(),
      alignRightLast: true,
    );
  }

  static pw.Widget _fuel(FuelStats fuel) {
    final rows = <List<String>>[
      [
        'Consommation moyenne',
        fuel.averageConsumption == null
            ? 'non mesurée'
            : '${fuel.averageConsumption!.toStringAsFixed(1)} L/100 km',
      ],
      [
        'Coût au kilomètre',
        fuel.costPerKm == null ? '—' : Fmt.money(fuel.costPerKm),
      ],
      ['Total carburant', Fmt.money(fuel.totalCost)],
      ['Litres', '${fuel.totalLiters.toStringAsFixed(0)} L'],
      ['Pleins', '${fuel.fillUps}'],
    ];
    return _table(
      headers: const ['Indicateur', 'Valeur'],
      rows: rows,
      alignRightLast: true,
    );
  }

  static pw.Widget _documents(CarnetData data) {
    if (data.documents.isEmpty) return _empty('Aucun document enregistré.');

    return _table(
      headers: ['Document', 'Année', 'Échéance', 'État'],
      rows: data.documents.map((d) {
        final state = d.isExpired
            ? 'expiré'
            : d.fileUrl == null
                ? 'sans scan'
                : 'valide';
        return [
          DocTypes.label(d.docType),
          '${d.year}',
          Fmt.dateShort(d.expiryDate),
          state,
        ];
      }).toList(),
    );
  }

  // ---- primitives -----------------------------------------------------

  static pw.Widget _empty(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Text(pdfSafe(text),
            style: pw.TextStyle(
                fontSize: 10, color: _muted, fontStyle: pw.FontStyle.italic)),
      );

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    bool alignRightLast = false,
  }) {
    pw.Widget cell(String text, {required bool header, required bool last}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          pdfSafe(text),
          textAlign:
              alignRightLast && last ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: 9,
            color: header ? _muted : _ink,
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    return pw.Table(
      border:
          const pw.TableBorder(horizontalInside: pw.BorderSide(color: _rule)),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _zebra),
          children: [
            for (var i = 0; i < headers.length; i++)
              cell(headers[i], header: true, last: i == headers.length - 1),
          ],
        ),
        for (final row in rows)
          pw.TableRow(
            children: [
              for (var i = 0; i < row.length; i++)
                cell(row[i], header: false, last: i == row.length - 1),
            ],
          ),
      ],
    );
  }
}
