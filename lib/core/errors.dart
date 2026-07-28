/// Turns an exception into something a French-speaking user can act on.
///
/// Every screen used to print `'Erreur : $e'`, which surfaces raw
/// `PostgrestException(message: JWT expired, code: PGRST301, ...)` or
/// `ClientException with SocketException` — English, technical, and with
/// no hint of what to do next.
///
/// Matching is on substrings of the exception text because supabase_flutter
/// reports most failures as message strings rather than typed errors.
String friendlyError(Object error) {
  final s = error.toString();

  // --- connectivity -----------------------------------------------------
  if (_containsAny(s, const [
    'SocketException',
    'Failed host lookup',
    'Connection closed',
    'Connection refused',
    'Network is unreachable',
    'ClientException',
  ])) {
    return 'Pas de connexion. Vérifiez votre réseau et réessayez.';
  }
  if (_containsAny(s, const ['TimeoutException', 'timed out'])) {
    return 'Le serveur met trop de temps à répondre. Réessayez.';
  }

  // --- session ----------------------------------------------------------
  if (_containsAny(s, const ['JWT expired', 'PGRST301', 'Invalid Refresh Token'])) {
    return 'Session expirée. Reconnectez-vous.';
  }
  if (s.contains('Invalid login')) return 'Email ou mot de passe incorrect.';
  if (s.contains('already registered')) return 'Ce compte existe déjà.';
  if (s.contains('Email not confirmed')) {
    return 'Email non confirmé — vérifiez votre boîte mail avant de vous '
        'connecter.';
  }
  if (_containsAny(s, const ['over_email_send_rate_limit', 'rate limit'])) {
    return 'Trop de tentatives. Patientez quelques minutes.';
  }

  // --- permissions / constraints ---------------------------------------
  if (_containsAny(s, const ['row-level security', 'PGRST116', '42501'])) {
    return "Vous n'avez pas accès à cet élément.";
  }
  if (s.contains('duplicate key')) {
    return 'Cet élément existe déjà.';
  }
  if (s.contains('violates foreign key')) {
    return 'Cet élément est encore utilisé ailleurs.';
  }

  // --- storage ----------------------------------------------------------
  if (_containsAny(s, const ['Payload too large', 'exceeded the maximum'])) {
    return 'Fichier trop volumineux.';
  }

  return 'Une erreur est survenue. Réessayez.';
}

bool _containsAny(String haystack, List<String> needles) =>
    needles.any(haystack.contains);
