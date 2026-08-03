import 'package:flutter/material.dart';

import '../../core/aurora_theme.dart';
import '../../screens/settings/aurora_settings_screen.dart';
import '../../screens/shell/quick_add_dial.dart' show QuickAddFab;
import 'aurora_floating_nav.dart';
import 'aurora_quick_add_sheet.dart';

/// The chrome every Aurora tab shares: the screen gradient, the floating
/// pill nav (hidden while the quick-add sheet is up), and the quick-add
/// trigger.
///
/// The FAB is placed explicitly at `right: 24, bottom: 96` rather than via
/// `Scaffold.floatingActionButton`'s default corner position — the
/// default sits ~16px from the edges, which overlaps
/// [AuroraFloatingNav] (the nav occupies the bottom 18-82px band; a
/// 58px FAB at the default offset would span roughly 16-74px, squarely
/// inside it).
class AuroraTabChrome extends StatefulWidget {
  const AuroraTabChrome({
    super.key,
    required this.tab,
    required this.onSelectTab,
    required this.body,
    required this.vehicleId,
  });

  final AuroraNavTab tab;
  final ValueChanged<AuroraNavTab> onSelectTab;
  final Widget body;

  /// Null hides the quick-add FAB — there is nothing to log against.
  final String? vehicleId;

  @override
  State<AuroraTabChrome> createState() => _AuroraTabChromeState();
}

class _AuroraTabChromeState extends State<AuroraTabChrome> {
  bool _sheetOpen = false;
  Offset? _dragStart;

  Future<void> _openQuickAdd() async {
    final id = widget.vehicleId;
    if (id == null) return;
    setState(() => _sheetOpen = true);
    await showAuroraQuickAddSheet(context, id);
    if (mounted) setState(() => _sheetOpen = false);
  }

  // A GestureDetector's HorizontalDragGestureRecognizer would enter the
  // same gesture arena as Ledger's horizontal filter-chip scroller and
  // could win it, freezing that scroller — confirmed live on device.
  // Listener sidesteps the arena entirely: it observes the raw pointer
  // trail independently, so nested scrollables keep working exactly as
  // before and this only ever *adds* a tab switch, never steals a drag.
  void _handlePointerDown(PointerDownEvent event) => _dragStart = event.position;

  void _handlePointerUp(PointerUpEvent event) {
    final start = _dragStart;
    _dragStart = null;
    if (start == null) return;
    final delta = event.position - start;
    // Require a decisive, mostly-horizontal swipe so an ordinary
    // vertical scroll (which always has some horizontal wobble) never
    // gets misread as a page change.
    if (delta.dx.abs() < 80 || delta.dx.abs() < delta.dy.abs() * 2) return;
    const tabs = AuroraNavTab.values;
    final current = widget.tab.index;
    if (delta.dx < 0 && current < tabs.length - 1) {
      widget.onSelectTab(tabs[current + 1]);
    } else if (delta.dx > 0 && current > 0) {
      widget.onSelectTab(tabs[current - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aurora = context.aurora;
    return Scaffold(
      backgroundColor: aurora.groundStart,
      // Settings now lives as a left-hand slide-out drawer rather than a
      // pushed route — reachable via Scaffold.of(context).openDrawer()
      // (Due's sliders chip) or a left-edge swipe, from any tab, since
      // this Scaffold is the one shared shell all four tabs sit inside.
      drawer: const AuroraSettingsDrawer(),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: aurora.screenGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _handlePointerDown,
                onPointerUp: _handlePointerUp,
                child: widget.body,
              ),
              if (!_sheetOpen)
                AuroraFloatingNav(current: widget.tab, onSelect: widget.onSelectTab),
              if (!_sheetOpen && widget.vehicleId != null)
                Positioned(
                  right: 24,
                  bottom: AuroraSpacing.bottomNavClearance,
                  child: QuickAddFab(open: _sheetOpen, onToggle: _openQuickAdd),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
