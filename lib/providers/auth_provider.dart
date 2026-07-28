import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
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
    // Without emailRedirectTo the link opens a browser that has no way to
    // hand the session back to the app, so the magic link never completed
    // on mobile.
    await Db.auth.signInWithOtp(
      email: email,
      emailRedirectTo: AppConfig.authRedirect,
    );
  }

  /// Sends a reset email. The link reopens the app, which then surfaces a
  /// "choose a new password" screen (see [AuthState] passwordRecovery
  /// handling in _AuthGate).
  Future<void> sendPasswordReset(String email) async {
    await Db.auth.resetPasswordForEmail(
      email,
      redirectTo: AppConfig.authRedirect,
    );
  }

  Future<void> updatePassword(String password) async {
    await Db.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() async {
    await Db.auth.signOut();
  }

  /// Permanently deletes the signed-in account and all of its data.
  ///
  /// Goes through the `delete-account` Edge Function: removing a row from
  /// auth.users requires the service_role key, which must never ship in
  /// the app. The function identifies the caller from their own JWT, so
  /// there is nothing to pass here.
  Future<void> deleteAccount() async {
    final res = await Db.client.functions.invoke('delete-account');
    if (res.status != 200) {
      throw Exception('delete-account failed (${res.status}): ${res.data}');
    }
  }
}
