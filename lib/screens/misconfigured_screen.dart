import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Shown when SUPABASE_URL / SUPABASE_ANON_KEY were not provided.
class MisconfiguredScreen extends StatelessWidget {
  const MisconfiguredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_suggest_outlined,
                  size: 56, color: AppColors.accent),
              const SizedBox(height: 16),
              const Text('Configuration Supabase manquante',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'Lancez l\'app avec vos identifiants Supabase :',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SelectableText(
                  'flutter run \\\n'
                  '  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \\\n'
                  '  --dart-define=SUPABASE_ANON_KEY=eyJhbGci...',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
