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

  /// Where Supabase sends the user back after a password-reset or
  /// magic-link email. Must match the intent-filter in AndroidManifest.xml,
  /// CFBundleURLTypes in ios/Runner/Info.plist, **and** the redirect
  /// allow-list in the Supabase dashboard (Authentication > URL
  /// Configuration) — the email link is refused otherwise.
  static const authRedirect = 'com.motora.app://auth-callback';
}

/// Storage bucket ids (mirror supabase/storage_buckets.sql).
class Buckets {
  static const vehiclePhotos = 'vehicle-photos';
  static const invoices = 'invoices';
  static const adminDocuments = 'admin-documents';
  static const mileagePhotos = 'mileage-photos';
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

/// Categories for spending that isn't maintenance and isn't fuel.
///
/// Chosen for Algeria: vignette and contrôle technique are recurring
/// paid formalities here, and amendes are frequent enough to be worth
/// their own line rather than hiding in "autre".
class ExpenseCategories {
  static const assurance = 'assurance';
  static const vignette = 'vignette';
  static const taxe = 'taxe';
  static const controleTechnique = 'controle_technique';
  static const peage = 'peage';
  static const parking = 'parking';
  static const lavage = 'lavage';
  static const amende = 'amende';
  static const accessoires = 'accessoires';
  static const autre = 'autre';

  static const all = <String>[
    assurance,
    vignette,
    taxe,
    controleTechnique,
    peage,
    parking,
    lavage,
    amende,
    accessoires,
    autre,
  ];

  static String label(String category) {
    switch (category) {
      case assurance:
        return 'Assurance';
      case vignette:
        return 'Vignette';
      case taxe:
        return 'Taxe';
      case controleTechnique:
        return 'Contrôle technique';
      case peage:
        return 'Péage';
      case parking:
        return 'Parking';
      case lavage:
        return 'Lavage';
      case amende:
        return 'Amende';
      case accessoires:
        return 'Accessoires';
      case autre:
        return 'Autre';
      default:
        return category;
    }
  }
}

/// Known administrative document types.
class DocTypes {
  static const vignette = 'vignette';
  static const assurance = 'assurance';
  static const controleTechnique = 'controle_technique';
  static const carteGrise = 'carte_grise';

  static const all = <String>[
    vignette,
    assurance,
    controleTechnique,
    carteGrise,
  ];

  static String label(String type) {
    switch (type) {
      case vignette:
        return 'Vignette';
      case assurance:
        return 'Assurance';
      case controleTechnique:
        return 'Contrôle technique';
      case carteGrise:
        return 'Carte grise';
      default:
        return type;
    }
  }
}
