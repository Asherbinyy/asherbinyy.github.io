import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/theme_factory.dart';
import 'package:nocturne/app/theme/tokens.dart';

/// Primary, dark artifact.
abstract final class NocturneTheme {
  /// Constructs the complete Nocturne theme.
  static ThemeData create({
    required double viewportWidth,
    bool isArabic = false,
  }) => ThemeFactory.create(
    tokens: nocturneTokens,
    brightness: Brightness.dark,
    viewportWidth: viewportWidth,
    isArabic: isArabic,
  );
}
