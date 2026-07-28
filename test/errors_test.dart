import 'dart:io';

import 'package:carnet_auto/core/errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('friendlyError', () {
    test('never leaks the raw exception text', () {
      const raw = 'PostgrestException(message: JWT expired, code: PGRST301)';
      final out = friendlyError(Exception(raw));
      expect(out, isNot(contains('PostgrestException')));
      expect(out, isNot(contains('PGRST301')));
    });

    test('names the network as the cause when it is', () {
      expect(
        friendlyError(const SocketException('Failed host lookup')),
        contains('connexion'),
      );
    });

    test('tells an expired session apart from a wrong password', () {
      final expired = friendlyError(
          Exception('PostgrestException(message: JWT expired, code: PGRST301)'));
      final wrong =
          friendlyError(Exception('AuthException: Invalid login credentials'));

      expect(expired, contains('Session expirée'));
      expect(wrong, contains('incorrect'));
      expect(expired, isNot(wrong));
    });

    test('falls back to a generic French message', () {
      final out = friendlyError(Exception('something entirely unexpected'));
      expect(out, 'Une erreur est survenue. Réessayez.');
    });
  });
}
