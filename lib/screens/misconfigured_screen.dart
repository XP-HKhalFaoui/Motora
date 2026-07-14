import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Shown when SUPABASE_URL / SUPABASE_ANON_KEY were not provided.
class MisconfiguredScreen extends StatelessWidget {
  const MisconfiguredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings_suggest_outlined, size: 56, color: p.accent),
              const SizedBox(height: 16),
              Text('Configuration Supabase manquante',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Lancez l\'app avec vos identifiants Supabase :',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  'flutter run \\\n'
                  '  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \\\n'
                  '  --dart-define=SUPABASE_ANON_KEY=eyJhbGci...',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: p.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
