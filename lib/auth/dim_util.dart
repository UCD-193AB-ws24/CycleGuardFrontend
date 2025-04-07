import 'package:flutter/widgets.dart';

class DimUtil{
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double safeWidth(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return MediaQuery.of(context).size.width - padding.left - padding.right;
  }

  static double safeHeight(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return MediaQuery.of(context).size.height - padding.top - padding.bottom;
  }
}

