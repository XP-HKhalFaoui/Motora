import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_text.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/striped_placeholder.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final auth = ref.read(authControllerProvider);
      if (_isSignUp) {
        final needsConfirmation =
            await auth.signUp(_email.text.trim(), _password.text);
        if (needsConfirmation && mounted) {
          setState(() => _info =
              'Compte créé — vérifiez votre email pour confirmer avant de vous connecter.');
        }
        // Otherwise the auth gate reacts to the session stream automatically.
      } else {
        await auth.signIn(_email.text.trim(), _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMagicLink() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() => _error = 'Entrez un email valide pour recevoir le lien.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await ref
          .read(authControllerProvider)
          .signInWithMagicLink(_email.text.trim());
      if (mounted) setState(() => _info = 'Lien magique envoyé — vérifiez vos emails.');
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('Invalid login')) return 'Email ou mot de passe incorrect.';
    if (s.contains('already registered')) return 'Ce compte existe déjà.';
    if (s.contains('Email not confirmed')) {
      return 'Email non confirmé — vérifiez votre boîte mail avant de vous connecter.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                p.surfaceElevated,
                                p.surface,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: p.border),
                          ),
                          child: Icon(Icons.directions_car_rounded,
                              size: 36, color: p.accent),
                        ),
                        const SizedBox(height: 18),
                        Text('Motora', style: AppText.wordmark(p.textPrimary)),
                        const SizedBox(height: 8),
                        Text("Votre carnet d'entretien auto",
                            style: TextStyle(
                                color: p.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 150,
                    child: StripedPlaceholder(
                      borderRadius: 22,
                      label: 'illustration · voiture',
                    ),
                  ),
                  const SizedBox(height: 30),
                  _FieldLabel('EMAIL', p),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: TextStyle(color: p.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'vous@email.com',
                      prefixIcon: Icon(Icons.mail_outline, color: p.textMuted),
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Email invalide'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('MOT DE PASSE', p),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    style: TextStyle(color: p.textPrimary),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_outline, color: p.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: p.textMuted),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? '6 caractères minimum'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!,
                        style: TextStyle(color: p.danger),
                        textAlign: TextAlign.center),
                  ],
                  if (_info != null) ...[
                    const SizedBox(height: 14),
                    Text(_info!,
                        style: TextStyle(color: p.ok),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_isSignUp
                                  ? 'Créer le compte'
                                  : 'Se connecter'),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _sendMagicLink,
                    icon: Icon(Icons.link, size: 20, color: p.textMuted),
                    label: const Text('Recevoir un lien magique'),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: GestureDetector(
                      onTap: _loading
                          ? null
                          : () => setState(() => _isSignUp = !_isSignUp),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          children: [
                            TextSpan(text: _isSignUp
                                ? 'Déjà un compte ? '
                                : 'Pas encore de compte ? '),
                            TextSpan(
                              text: _isSignUp
                                  ? 'Se connecter'
                                  : 'Créer un compte',
                              style: TextStyle(
                                  color: p.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, this.p);
  final String text;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            color: p.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: .3));
  }
}
