import 'package:flutter/material.dart';

/// Best-effort icon for a maintenance type label (French), mirroring the
/// icon set used throughout Motora.dc.html (oil_barrel, disc_full, etc).
IconData maintenanceIconFor(String label) {
  final l = label.toLowerCase();
  if (l.contains('vidange') || l.contains('huile')) return Icons.oil_barrel;
  if (l.contains('plaquette') || l.contains('frein')) return Icons.disc_full;
  if (l.contains('batterie')) return Icons.battery_charging_full;
  if (l.contains('pneu')) return Icons.tire_repair;
  if (l.contains('distribution') || l.contains('courroie') || l.contains('kit')) {
    return Icons.settings_input_component;
  }
  if (l.contains('contrôle') || l.contains('controle') || l.contains('ct')) {
    return Icons.fact_check;
  }
  if (l.contains('assurance')) return Icons.verified_user;
  if (l.contains('vignette')) return Icons.local_activity;
  return Icons.build_circle_outlined;
}
