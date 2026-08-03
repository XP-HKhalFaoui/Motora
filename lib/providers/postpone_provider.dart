import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefix = 'postpone.';

/// Default snooze length for the Due screen's "Reporter" action — not
/// specified anywhere in the design spec, just a reasonable single default
/// since the spec only asks that the button "actually pushes the
/// échéance out", not for a chooser.
const kPostponeDuration = Duration(days: 7);

/// Local-only "Reporter" overrides: pushes an échéance's urgent status
/// down to "à surveiller" for a week without touching its underlying
/// interval, last-done date, or the Supabase schema — everything the
/// button does lives in SharedPreferences on this device.
final postponeProvider =
    AsyncNotifierProvider<PostponeNotifier, Map<String, DateTime>>(PostponeNotifier.new);

class PostponeNotifier extends AsyncNotifier<Map<String, DateTime>> {
  late SharedPreferences _prefs;

  @override
  Future<Map<String, DateTime>> build() async {
    _prefs = await SharedPreferences.getInstance();
    final map = <String, DateTime>{};
    final now = DateTime.now();
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(_kPrefix)) continue;
      final until = DateTime.tryParse(_prefs.getString(key) ?? '');
      if (until != null && until.isAfter(now)) {
        map[key.substring(_kPrefix.length)] = until;
      }
    }
    return map;
  }

  bool isPostponed(String id) {
    final until = (state.value ?? const {})[id];
    return until != null && until.isAfter(DateTime.now());
  }

  Future<void> postpone(String id, {Duration duration = kPostponeDuration}) async {
    final until = DateTime.now().add(duration);
    await _prefs.setString('$_kPrefix$id', until.toIso8601String());
    state = AsyncData({...state.value ?? const {}, id: until});
  }
}
