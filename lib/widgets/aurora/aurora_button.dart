import 'package:flutter/material.dart';

import '../../core/aurora_theme.dart';

/// The accent-filled pill button reused for the New-entry footer
/// ("Enregistrer l'entrée", height 52/15px) and the Due urgent card's
/// "Marquer comme fait" (44px-equivalent/13px). Label is always
/// [AuroraColors.ink] per spec ("fill accent, label ... in ink").
class AuroraPrimaryButton extends StatelessWidget {
  const AuroraPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 52,
    this.fontSize = 15,
    this.expand = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final bool expand;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final content = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AuroraColors.ink),
          )
        : Text(label,
            style: AuroraText.tabularValue(AuroraColors.ink,
                size: fontSize, weight: FontWeight.w600));

    final button = Container(
      height: height,
      width: expand ? double.infinity : null,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AuroraRadii.pill)),
        boxShadow: AuroraShadows.accentButton,
      ),
      child: Material(
        color: AuroraColors.accent,
        borderRadius: BorderRadius.circular(AuroraRadii.pill),
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(AuroraRadii.pill),
          child: Center(child: content),
        ),
      ),
    );

    return expand ? button : IntrinsicWidth(child: button);
  }
}

/// The outline counterpart — Due urgent card's "Reporter":
/// `onDark @ 26%` 1px border, label onDark, no fill.
class AuroraOutlineButton extends StatelessWidget {
  const AuroraOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 44,
    this.fontSize = 13,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: height,
      width: expand ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AuroraRadii.pill),
        border: Border.all(color: AuroraColors.onDarkOutlineBorder()),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AuroraRadii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AuroraRadii.pill),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  color: AuroraColors.onDark,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: AuroraText.meta(AuroraColors.onDark).fontFamily,
                )),
          ),
        ),
      ),
    );
    return expand ? button : IntrinsicWidth(child: button);
  }
}
