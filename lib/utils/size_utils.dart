import 'package:flutter/material.dart';

class SizeUtils {

  static double fontSize(BuildContext context, double basicFontSize, {double scaleFactor = 0.05}) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * scaleFactor * basicFontSize * 0.04;
  }

}