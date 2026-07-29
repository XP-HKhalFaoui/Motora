import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The four destinations of the bottom bar. The FAB sits in the notch
/// between [history] and [due] and is not a destination.
enum ShellTab { vehicle, history, due, more }

/// Which tab the shell is showing.
///
/// A provider rather than local state because things outside the shell
/// need to steer it: a tapped notification lands on [ShellTab.due], and
/// the Véhicule digest links through to the other tabs.
final shellTabProvider = StateProvider<ShellTab>((ref) => ShellTab.vehicle);
