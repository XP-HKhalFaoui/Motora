import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/new_password_screen.dart';
import 'screens/misconfigured_screen.dart';
import 'screens/shell/app_shell.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // `anonKey` is deprecated in favour of `publishableKey`. The
      // --dart-define is still named SUPABASE_ANON_KEY so existing
      // env.json files and build scripts keep working; only the
      // parameter changed. Both accept the sb_publishable_… format.
      publishableKey: AppConfig.supabaseAnonKey,
    );
    await NotificationService.instance.init();
  }

  runApp(const ProviderScope(child: MotoraApp()));
}

class MotoraApp extends ConsumerWidget {
  const MotoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // While settings load, follow the OS rather than assuming dark — a
    // light-mode user used to get a dark flash on every cold start.
    final themeMode =
        ref.watch(settingsProvider).value?.themeMode ?? ThemeMode.system;

    return MaterialApp(
      title: 'Motora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Without these, Material's own widgets fall back to English inside
      // an otherwise French app — the date pickers used for interventions
      // and documents showed "Cancel"/"OK", as did the text-selection menu.
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppConfig.isConfigured
          ? const _AuthGate()
          : const MisconfiguredScreen(),
    );
  }
}

/// Shows login, the new-password prompt, or the app shell depending on the
/// Supabase session.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  /// Set when a password-reset link reopens the app. Supabase has already
  /// created a session by then, so without this the user would be dropped
  /// straight into the app and never get to set the password they asked
  /// to reset.
  bool _recovering = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      final event = next.value?.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        setState(() => _recovering = true);
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() => _recovering = false);
      }
    });

    final user = ref.watch(currentUserProvider);
    if (user == null) return const LoginScreen();
    if (_recovering) {
      return NewPasswordScreen(
        onDone: () => setState(() => _recovering = false),
      );
    }
    return const AppShell();
  }
}
