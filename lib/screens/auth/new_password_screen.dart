import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Shown after a password-reset link reopens the app.
///
/// At this point Supabase has already exchanged the link for a session, so
/// the user is technically signed in — they just can't be let into the app
/// until they've chosen the new password they asked for.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _password.text;
    if (password.length < 6) {
      setState(() => _error = 'Au moins 6 caractères.');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = 'Les deux mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider).updatePassword(password);
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nouveau mot de passe',
                    textAlign: TextAlign.center,
                    style: AppText.screenTitle(p.textPrimary, size: 22)),
                const SizedBox(height: 8),
                Text(
                  'Choisissez un nouveau mot de passe pour votre compte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  autofocus: true,
                  style: TextStyle(color: p.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Afficher' : 'Masquer',
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: p.textMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirm,
                  obscureText: _obscure,
                  style: TextStyle(color: p.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Confirmer'),
                  onSubmitted: (_) => _save(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.danger)),
                ],
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
