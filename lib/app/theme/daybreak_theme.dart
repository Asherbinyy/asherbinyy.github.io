import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/theme_factory.dart';
import 'package:nocturne/app/theme/tokens.dart';

/// Secondary artifact: technical drawing on warm paper.
abstract final class DaybreakTheme {
  /// Constructs the complete Daybreak theme.
  static ThemeData create({
    required double viewportWidth,
    bool isArabic = false,
  }) => ThemeFactory.create(
    tokens: daybreakTokens,
    brightness: Brightness.light,
    viewportWidth: viewportWidth,
    isArabic: isArabic,
  );
}
