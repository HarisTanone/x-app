import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'Plus Jakarta Sans';
  
  // Text Sizes
  static const double textXs = 12.0;
  static const double textSm = 14.0;
  static const double textBase = 16.0;
  static const double textLg = 18.0;
  static const double textXl = 20.0;
  static const double text2xl = 24.0;
  static const double text3xl = 30.0;
  
  // Text Styles
  static const TextStyle xs = TextStyle(
    fontFamily: fontFamily,
    fontSize: textXs,
  );
  
  static const TextStyle sm = TextStyle(
    fontFamily: fontFamily,
    fontSize: textSm,
  );
  
  static const TextStyle base = TextStyle(
    fontFamily: fontFamily,
    fontSize: textBase,
  );
  
  static const TextStyle lg = TextStyle(
    fontFamily: fontFamily,
    fontSize: textLg,
  );
  
  static const TextStyle xl = TextStyle(
    fontFamily: fontFamily,
    fontSize: textXl,
  );
  
  static const TextStyle xxl = TextStyle(
    fontFamily: fontFamily,
    fontSize: text2xl,
  );
  
  static const TextStyle xxxl = TextStyle(
    fontFamily: fontFamily,
    fontSize: text3xl,
  );
}