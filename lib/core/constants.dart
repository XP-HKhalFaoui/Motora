/// App-wide constants and Supabase configuration.
///
/// Provide credentials at build/run time with --dart-define, e.g.:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
class AppConfig {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

/// Storage bucket ids (mirror supabase/storage_buckets.sql).
class Buckets {
  static const vehiclePhotos = 'vehicle-photos';
  static const invoices = 'invoices';
  static const adminDocuments = 'admin-documents';
}

/// Business thresholds used for alerts and predictions.
class Thresholds {
  /// Alert when remaining km before a maintenance drops below this.
  static const int kmAlert = 500;

  /// Alert when a due date (maintenance or document) is closer than this.
  static const int daysAlert = 30;

  /// Rolling window (months) used to compute the monthly km average.
  static const int avgWindowMonths = 6;

  /// Fallback monthly average when history is too thin to estimate.
  static const double fallbackKmPerMonth = 1000;
}

/// Known administrative document types.
class DocTypes {
  static const vignette = 'vignette';
  static const assurance = 'assurance';
  static const controleTechnique = 'controle_technique';

  static const all = <String>[vignette, assurance, controleTechnique];

  static String label(String type) {
    switch (type) {
      case vignette:
        return 'Vignette';
      case assurance:
        return 'Assurance';
      case controleTechnique:
        return 'Contrôle technique';
      default:
        return type;
    }
  }
}
