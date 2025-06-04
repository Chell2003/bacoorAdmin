import 'package:flutter/material.dart';

class TextScale {
  static double getScaleFactor(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    
    if (width < 768) { // Mobile
      return 0.85;
    } else if (width < 1200) { // Tablet
      return 0.9;
    } else if (width < 1600) { // Desktop
      return 1.0;
    } else { // Large Desktop
      return 1.1;
    }
  }

  static TextStyle? scale(TextStyle? style, BuildContext context) {
    if (style == null) return null;
    double scaleFactor = getScaleFactor(context);
    return style.copyWith(
      fontSize: style.fontSize != null ? style.fontSize! * scaleFactor : null,
    );
  }

  static double getFontSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }
}
