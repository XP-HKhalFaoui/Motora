import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/misconfigured_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    await NotificationService.instance.init();
  }

  runApp(const ProviderScope(child: CarnetAutoApp()));
}

class CarnetAutoApp extends StatelessWidget {
  const CarnetAutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carnet Auto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AppConfig.isConfigured
          ? const _AuthGate()
          : const MisconfiguredScreen(),
    );
  }
}

/// Shows login or home depending on the Supabase session.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user == null ? const LoginScreen() : const HomeScreen();
  }
}
