import 'package:flutter/material.dart';

/// Session-scoped dark/light mode toggle, shared across screens via
/// constructor injection like the rest of the app's dependencies.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);

  bool get isDark => value == ThemeMode.dark;

  void toggle() {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}
