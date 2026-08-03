import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/aurora/aurora_floating_nav.dart';

/// Which Aurora tab the shell is showing. Kept separate from the legacy
/// `shellTabProvider`/`ShellTab` (providers/shell_provider.dart) rather
/// than repurposing it — several not-yet-migrated screens still compile
/// against the old enum's values, and changing them out from under those
/// screens would break code this redesign hasn't touched yet.
final auroraShellTabProvider = StateProvider<AuroraNavTab>((ref) => AuroraNavTab.home);
