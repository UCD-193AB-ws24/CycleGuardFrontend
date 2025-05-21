import 'package:flutter/material.dart';

/// Returns text color based on current theme brightness.
Color themedTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white70
      : Colors.black;
}

/// Standard button styling used throughout the app.
ButtonStyle themedButtonStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return ElevatedButton.styleFrom(
    backgroundColor: isDark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.onInverseSurface,
    foregroundColor: isDark
        ? Colors.white70
        : Theme.of(context).colorScheme.primary,
  );
}

/// Standard InputDecoration for text fields with theme support.
InputDecoration themedInputDecoration(BuildContext context, String label) {
  final color = themedTextColor(context);
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: color),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: color.withAlpha(100)),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: color),
    ),
  );
}

/// Returns true if current theme is dark mode.
bool inDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

/// Returns light or dark color depending on current theme.
Color themedColor(BuildContext context, Color light, Color dark) {
  return inDarkMode(context) ? dark : light;
}