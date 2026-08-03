import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the "Nocturne Aurora" redesign — see
/// `design_handoff_motora_aurora/README.md`. Every literal in this file is
/// copied from that spec; it is the single source of truth new (Aurora)
/// screens and widgets read from. It is additive: existing screens keep
/// using [AppPalette]/[AppText] (core/theme.dart, core/app_text.dart)
/// until they are individually migrated.
///
/// The spec is high-fidelity for its **light** ground only; dark mode is
/// an approved but loosely-specified inversion ("ground → #161826, cards →
/// #232532, text → #E9E9ED, accent unchanged, hairline borders instead of
/// shadows"). Tokens the recipe doesn't name explicitly (hairlineStrong,
/// neutralChip, iconMutedOnWhite in dark mode) are interpolated here from
/// the onDark opacity scale the spec *does* give for dark surfaces — they
/// are not literal spec values, just a reasonable extension of it.
class AuroraColors {
  AuroraColors._();

  // ---- Core (invariant across brightness) ----------------------------
  static const accent = Color(0xFF9184D9);
  static const ink = Color(0xFF161826);
  static const onDark = Color(0xFFE9E9ED);

  // ---- Light ground: derived, precomputed literals --------------------
  static const card = Color(0xFFFFFFFF);
  static const bgTop = Color(0xFFF8F8FD);
  static const bgMid = Color(0xFFEDEBF9);
  static const bgBottom = Color(0xFFFAF9FD);

  static const accentTint06 = Color(0xFFF7F6FC);
  static const accentTint08 = Color(0xFFF6F5FC);
  static const accentTint12 = Color(0xFFF2F0FA);
  static const accentTint13 = Color(0xFFF1EFFA);
  static const accentTint14 = Color(0xFFF0EEFA);
  static const accentTint16 = Color(0xFFEFEDF9);
  static const accentTint22 = Color(0xFFE7E4F7);
  static const accentTint24 = Color(0xFFE5E2F6);
  static const accentTint32 = Color(0xFFDCD8F3);
  static const accentTint45 = Color(0xFFCEC8EE);
  static const accentTint55 = Color(0xFFC3BBEA);

  static const muted = Color(0xFF6A6B74);
  static const mutedSoft = Color(0xFF73747D);
  static const hairline = Color(0xFFE3E3E5);
  static const hairlineStrong = Color(0xFFDEDEE1);
  static const neutralChip = Color(0xFFEFEFF0);
  static const iconMutedOnWhite = Color(0xFFA2A3A8);

  /// Vehicle-photo placeholder gradient's end stop (start is
  /// [accentTint24]) — given only in the Home screen section, not the
  /// global token table, but still a spec literal.
  static const vehiclePlaceholderEnd = Color(0xFFF5F4FB);

  // ---- Dark ground (stock-Nocturne inversion recipe) -------------------
  static const darkGround = Color(0xFF161826);
  static const darkCard = Color(0xFF232532);

  /// `rgba(233,233,237,.16)` — replaces card shadows in dark mode.
  static Color get darkHairlineBorder => onDark.withValues(alpha: .16);

  // ---- Opacity helpers named exactly per the spec's "on ink surfaces"
  // and "accent tints on dark" rules. These apply on ANY dark surface —
  // including the hero/nav "dark cards" that sit inside the light-mode
  // screens, not only in a fully dark-mode app.
  static Color onDarkSecondary() => onDark.withValues(alpha: .62);
  static Color onDarkInactiveIcon() => onDark.withValues(alpha: .55);
  static Color onDarkOutlineBorder() => onDark.withValues(alpha: .26);
  static Color onDarkProgressTrack() => onDark.withValues(alpha: .14);
  static Color accentChipOnDark() => accent.withValues(alpha: .26);

  /// A tint token's numeric suffix is literally its opacity of [accent]
  /// over the surface it sits on (accentTint14 = accent @ 14% over white —
  /// verified against the literal hex above). Dark mode has no
  /// precomputed-over-#232532 literals in the spec, so tints there are
  /// generated with this same percentage against whatever [surface] is
  /// passed — the mathematically faithful generalization of the literals.
  static Color tintOnSurface(double percent, Color surface) =>
      Color.alphaBlend(accent.withValues(alpha: percent), surface);
}

/// Inter 400/500/600 only — no other family, per spec. Tabular figures are
/// opt-in via [tabular], and are mandatory (per spec) on money, mileage,
/// dates, litres and counters.
class AuroraText {
  AuroraText._();

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required Color color,
    bool tabular = false,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontFeatures:
            tabular ? const [FontFeature.tabularFigures()] : null,
      );

  /// "Échéances", "Journal", "Rapports" — 22/600.
  static TextStyle screenTitle(Color color) =>
      _style(size: 22, weight: FontWeight.w600, color: color);

  /// Totals, mileage — 26/600, tabular.
  static TextStyle heroMetric(Color color) =>
      _style(size: 26, weight: FontWeight.w600, color: color, tabular: true);

  /// Card title / dark-card headline — 18-19/600.
  static TextStyle cardTitle(Color color, {double size = 19}) =>
      _style(size: size, weight: FontWeight.w600, color: color);

  /// "Activité récente", "Juillet 2026" — 13-14/600.
  static TextStyle sectionLabel(Color color, {double size = 13.5}) =>
      _style(size: size, weight: FontWeight.w600, color: color);

  /// List row title — 14-15/500.
  static TextStyle listRowTitle(Color color, {double size = 15}) =>
      _style(size: size, weight: FontWeight.w500, color: color);

  /// Body / field value — 15/400.
  static TextStyle bodyValue(Color color) =>
      _style(size: 15, weight: FontWeight.w400, color: color);

  /// Meta / caption — 11-12/400, normally colored [AuroraColors.muted].
  static TextStyle meta(Color color, {double size = 11.5, bool tabular = false}) =>
      _style(size: size, weight: FontWeight.w400, color: color, tabular: tabular);

  /// Chip / badge — 11/600.
  static TextStyle chipBadge(Color color) =>
      _style(size: 11, weight: FontWeight.w600, color: color);

  /// Axis label — 10/400, normally colored [AuroraColors.mutedSoft].
  static TextStyle axisLabel(Color color) =>
      _style(size: 10, weight: FontWeight.w400, color: color);

  /// Status bar — 12/500.
  static TextStyle statusBar(Color color) =>
      _style(size: 12, weight: FontWeight.w500, color: color);

  /// A tabular value at an arbitrary size/weight not covered above (e.g.
  /// a stat-tile value at 15/600, or a ledger amount at 14/600).
  static TextStyle tabularValue(Color color,
          {required double size, FontWeight weight = FontWeight.w600}) =>
      _style(size: size, weight: weight, color: color, tabular: true);
}

class AuroraRadii {
  AuroraRadii._();
  static const screenFrame = 36.0;
  static const largeCard = 26.0;
  static const standardCard = 24.0;
  static const smallCard = 20.0;
  static const listRow = 18.0;
  static const listRowLarge = 20.0;
  static const iconChipSmall = 11.0;
  static const iconChipLarge = 14.0;
  static const imageSlot = 16.0;
  static const pill = 999.0;
  static const progressBar = 3.0;
}

class AuroraSpacing {
  AuroraSpacing._();
  static const screenPaddingH = 18.0;
  static const blockGap = 13.5;
  static const cardPaddingLarge = 16.0;
  static const cardPaddingRow = 13.0;
  static const chipPaddingH = 12.0;
  static const chipPaddingV = 8.0;

  /// Every scrollable body under the floating nav needs this much bottom
  /// padding so the last item clears the bar.
  static const bottomNavClearance = 96.0;
}

class AuroraShadows {
  AuroraShadows._();

  static const cardSoft = [
    BoxShadow(color: Color.fromRGBO(40, 36, 80, 0.06), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const cardRaised = [
    BoxShadow(color: Color.fromRGBO(40, 36, 80, 0.07), blurRadius: 22, offset: Offset(0, 6)),
  ];

  /// Dark card / floating nav. The spec gives a 0.30-0.36 alpha range;
  /// 0.33 is the midpoint.
  static const darkCard = [
    BoxShadow(color: Color.fromRGBO(22, 24, 38, 0.33), blurRadius: 34, offset: Offset(0, 14)),
  ];

  /// Accent button. 0.36-0.40 range; 0.38 is the midpoint.
  static const accentButton = [
    BoxShadow(color: Color.fromRGBO(145, 132, 217, 0.38), blurRadius: 26, offset: Offset(0, 10)),
  ];

  static const bottomSheet = [
    BoxShadow(color: Color.fromRGBO(40, 36, 80, 0.16), blurRadius: 40, offset: Offset(0, -8)),
  ];

  /// Inactive filter chip — a separate, slightly tighter shadow than
  /// [cardSoft], literal to the Ledger filter-chip spec.
  static const filterChip = [
    BoxShadow(color: Color.fromRGBO(40, 36, 80, 0.06), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

/// Brightness-aware slice of the Aurora tokens — the handful of values
/// that must flip between the spec's light ground and the approved dark
/// inversion. Everything else (accent, text roles, radii, shadows) is
/// invariant and read straight off [AuroraColors]/[AuroraText]/etc.
class AuroraPalette extends ThemeExtension<AuroraPalette> {
  const AuroraPalette({
    required this.card,
    required this.groundStart,
    required this.groundMid,
    required this.groundEnd,
    required this.textPrimary,
    required this.muted,
    required this.mutedSoft,
    required this.hairline,
    required this.hairlineStrong,
    required this.neutralChip,
    required this.iconMutedOnWhite,
    required this.useCardShadows,
  });

  /// Regular card fill. White in light mode; `#232532` in dark — the
  /// inversion recipe gives cards a single tone, so the light mode's
  /// separate "dark hero card" (ink-filled, for emphasis) has no distinct
  /// dark-mode counterpart: it collapses onto this same [card] color.
  final Color card;

  final Color groundStart;
  final Color groundMid;
  final Color groundEnd;

  final Color textPrimary;
  final Color muted;
  final Color mutedSoft;
  final Color hairline;
  final Color hairlineStrong;
  final Color neutralChip;
  final Color iconMutedOnWhite;

  /// Light mode uses soft drop shadows; dark mode (stock Nocturne) drops
  /// them for a 1px [AuroraColors.darkHairlineBorder] instead.
  final bool useCardShadows;

  /// Always [AuroraColors.ink] — the fill for "dark" surfaces (hero card,
  /// floating nav) that exist even inside the light-mode screens.
  Color get heroCardFill => useCardShadows ? AuroraColors.ink : card;

  /// Always [AuroraColors.onDark] — text/icons on [heroCardFill].
  Color get onHeroCard => AuroraColors.onDark;

  Color get accent => AuroraColors.accent;

  LinearGradient get screenGradient => LinearGradient(
        // CSS 168deg, converted to a unit direction vector: dx = sin(168°),
        // dy = -cos(168°) — "nearly vertical, top-left to bottom-right"
        // exactly as the spec describes it.
        begin: const Alignment(-0.2079, -0.9781),
        end: const Alignment(0.2079, 0.9781),
        colors: [groundStart, groundMid, groundEnd],
        stops: const [0, 0.58, 1],
      );

  static const light = AuroraPalette(
    card: AuroraColors.card,
    groundStart: AuroraColors.bgTop,
    groundMid: AuroraColors.bgMid,
    groundEnd: AuroraColors.bgBottom,
    textPrimary: AuroraColors.ink,
    muted: AuroraColors.muted,
    mutedSoft: AuroraColors.mutedSoft,
    hairline: AuroraColors.hairline,
    hairlineStrong: AuroraColors.hairlineStrong,
    neutralChip: AuroraColors.neutralChip,
    iconMutedOnWhite: AuroraColors.iconMutedOnWhite,
    useCardShadows: true,
  );

  static final dark = AuroraPalette(
    card: AuroraColors.darkCard,
    groundStart: AuroraColors.darkGround,
    groundMid: AuroraColors.darkGround,
    groundEnd: AuroraColors.darkGround,
    textPrimary: AuroraColors.onDark,
    muted: AuroraColors.onDarkSecondary(),
    mutedSoft: AuroraColors.onDarkInactiveIcon(),
    hairline: AuroraColors.darkHairlineBorder,
    // Not given literally by the recipe — interpolated a step stronger
    // than [hairline] on the same onDark opacity scale.
    hairlineStrong: AuroraColors.onDark.withValues(alpha: .20),
    neutralChip: AuroraColors.onDark.withValues(alpha: .10),
    iconMutedOnWhite: AuroraColors.onDark.withValues(alpha: .45),
    useCardShadows: false,
  );

  @override
  AuroraPalette copyWith({
    Color? card,
    Color? groundStart,
    Color? groundMid,
    Color? groundEnd,
    Color? textPrimary,
    Color? muted,
    Color? mutedSoft,
    Color? hairline,
    Color? hairlineStrong,
    Color? neutralChip,
    Color? iconMutedOnWhite,
    bool? useCardShadows,
  }) =>
      AuroraPalette(
        card: card ?? this.card,
        groundStart: groundStart ?? this.groundStart,
        groundMid: groundMid ?? this.groundMid,
        groundEnd: groundEnd ?? this.groundEnd,
        textPrimary: textPrimary ?? this.textPrimary,
        muted: muted ?? this.muted,
        mutedSoft: mutedSoft ?? this.mutedSoft,
        hairline: hairline ?? this.hairline,
        hairlineStrong: hairlineStrong ?? this.hairlineStrong,
        neutralChip: neutralChip ?? this.neutralChip,
        iconMutedOnWhite: iconMutedOnWhite ?? this.iconMutedOnWhite,
        useCardShadows: useCardShadows ?? this.useCardShadows,
      );

  @override
  AuroraPalette lerp(ThemeExtension<AuroraPalette>? other, double t) {
    if (other is! AuroraPalette) return this;
    return AuroraPalette(
      card: Color.lerp(card, other.card, t)!,
      groundStart: Color.lerp(groundStart, other.groundStart, t)!,
      groundMid: Color.lerp(groundMid, other.groundMid, t)!,
      groundEnd: Color.lerp(groundEnd, other.groundEnd, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedSoft: Color.lerp(mutedSoft, other.mutedSoft, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairlineStrong: Color.lerp(hairlineStrong, other.hairlineStrong, t)!,
      neutralChip: Color.lerp(neutralChip, other.neutralChip, t)!,
      iconMutedOnWhite:
          Color.lerp(iconMutedOnWhite, other.iconMutedOnWhite, t)!,
      useCardShadows: t < 0.5 ? useCardShadows : other.useCardShadows,
    );
  }
}

/// `context.aurora.accent`, `context.aurora.screenGradient`, etc.
extension AuroraPaletteContext on BuildContext {
  AuroraPalette get aurora => Theme.of(this).extension<AuroraPalette>()!;
}
