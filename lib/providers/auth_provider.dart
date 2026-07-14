import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';

/// Streams Supabase auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Db.auth.onAuthStateChange;
});

/// Convenience: current user (null when logged out).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return Db.currentUser;
});

/// Auth actions.
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController();
});

class AuthController {
  Future<void> signIn(String email, String password) async {
    await Db.auth.signInWithPassword(email: email, password: password);
  }

  /// Returns true if the account needs email confirmation before it can
  /// sign in (no session was created yet).
  Future<bool> signUp(String email, String password) async {
    final res = await Db.auth.signUp(email: email, password: password);
    return res.session == null;
  }

  Future<void> signInWithMagicLink(String email) async {
    await Db.auth.signInWithOtp(email: email);
  }

  Future<void> signOut() async {
    await Db.auth.signOut();
  }
}
