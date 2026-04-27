import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgDeep = Color(0xFF080808);
  static const glassBg = Color(0x14FFFFFF);
  static const glassBorder = Color(0x26FFFFFF);
  static const glassShine = Color(0x38FFFFFF);
  static const silver = Color(0xFFC8C8C8);
  static const silverDim = Color(0xFF888888);
  static const silverBright = Color(0xFFE8E8E8);
  static const textPrimary = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFF888888);

  static TextStyle syne({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w800,
    Color color = textPrimary,
    double letterSpacing = -0.5,
  }) {
    return GoogleFonts.syne(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle dmSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glassBg,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
