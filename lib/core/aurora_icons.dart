import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'constants.dart';

/// Best-effort icon for a maintenance type label, restricted to the fixed
/// Phosphor set the Aurora spec allows ("Icons used: ..." — no other
/// glyphs anywhere). Mirrors the fuzzy French matching
/// [maintenanceIconFor] already does for the legacy Material-icon
/// screens, just mapped onto Aurora's narrower vocabulary.
PhosphorIconData auroraIconForMaintenance(String label) {
  final l = label.toLowerCase();
  if (l.contains('vidange') || l.contains('huile')) return PhosphorIconsFill.drop;
  if (l.contains('plaquette') || l.contains('frein') || l.contains('disque')) {
    return PhosphorIconsFill.gear;
  }
  if (l.contains('pneu')) return PhosphorIconsFill.tire;
  if (l.contains('assurance')) return PhosphorIconsFill.shieldCheck;
  if (l.contains('vignette')) return PhosphorIconsFill.ticket;
  if (l.contains('contrôle') || l.contains('controle')) return PhosphorIconsFill.shieldCheck;
  return PhosphorIconsFill.wrench;
}

/// Same, for an [AdminDocument.docType] (a fixed enum, unlike maintenance
/// labels — no fuzzy matching needed).
PhosphorIconData auroraIconForDocument(String docType) {
  switch (docType) {
    case DocTypes.vignette:
      return PhosphorIconsFill.ticket;
    case DocTypes.assurance:
      return PhosphorIconsFill.shieldCheck;
    case DocTypes.controleTechnique:
      return PhosphorIconsFill.shieldCheck;
    case DocTypes.carteGrise:
      return PhosphorIconsFill.carProfile;
    default:
      return PhosphorIconsFill.fileText;
  }
}

/// For an [ExpenseCategories] value. Ledger rows the entry is neutral
/// (muted icon on a gray chip, per spec) rather than accent — so the
/// exact glyph matters less, but a couple of categories have an obvious
/// match within the restricted set.
PhosphorIconData auroraIconForExpenseCategory(String category) {
  switch (category) {
    case ExpenseCategories.assurance:
    case ExpenseCategories.controleTechnique:
      return PhosphorIconsFill.shieldCheck;
    case ExpenseCategories.vignette:
      return PhosphorIconsFill.ticket;
    default:
      return PhosphorIconsFill.currencyEur;
  }
}
