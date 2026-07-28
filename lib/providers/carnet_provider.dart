import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../services/carnet_pdf_service.dart';
import '../services/prediction_service.dart';
import 'document_provider.dart';
import 'maintenance_provider.dart';
import 'vehicle_provider.dart';

final carnetExporterProvider = Provider<CarnetExporter>(CarnetExporter.new);

/// Builds and shares the "carnet d'entretien" PDF for one vehicle.
class CarnetExporter {
  CarnetExporter(this.ref);
  final Ref ref;

  Future<void> share(String vehicleId) async {
    final vehicle = ref.read(vehicleByIdProvider(vehicleId));
    if (vehicle == null) {
      throw StateError('Véhicule introuvable');
    }

    // .future rather than .value: the export must include everything, even
    // sections the user hasn't opened yet in this session.
    final predictions = await ref.read(predictionsProvider(vehicleId).future);
    final history =
        await ref.read(maintenanceHistoryProvider(vehicleId).future);
    final documents = await ref.read(documentsProvider(vehicleId).future);
    final logs = await ref.read(mileageLogsProvider(vehicleId).future);

    final bytes = await CarnetPdfService.build(CarnetData(
      vehicle: vehicle,
      predictions: predictions,
      history: history,
      documents: documents,
      kmPerMonth: PredictionService.measuredMonthlyKmAverage(logs),
      generatedAt: DateTime.now(),
    ));

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'carnet-motora-${_slug(vehicle.name)}.pdf',
    );
  }

  static String _slug(String name) {
    final ascii = name
        .toLowerCase()
        .replaceAll(RegExp('[àâä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[îï]'), 'i')
        .replaceAll(RegExp('[ôö]'), 'o')
        .replaceAll(RegExp('[ùûü]'), 'u')
        .replaceAll('ç', 'c');
    final slug =
        ascii.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty ? 'vehicule' : slug;
  }
}
