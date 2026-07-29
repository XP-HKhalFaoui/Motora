import 'package:flutter/material.dart';

import '../../core/app_text.dart';
import '../../core/theme.dart';

/// Scaffold around a hub section that is no longer a hub section.
///
/// Documents, Km and Carburant were segments of the vehicle hub. With the
/// hub gone they are pushed as their own screens — from the Véhicule
/// digest or from Plus — and this supplies the chrome they never needed
/// before: a title and a way back.
class SectionScreen extends StatelessWidget {
  const SectionScreen({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        title: Text(title, style: AppText.screenTitle(p.textPrimary, size: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: child,
      ),
    );
  }
}
