import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/supabase_service.dart';

/// Single shared instance of the data service.
final supabaseServiceProvider =
    Provider<SupabaseService>((ref) => SupabaseService());
