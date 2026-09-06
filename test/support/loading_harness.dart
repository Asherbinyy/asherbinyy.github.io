import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/theme/daybreak_theme.dart';
import 'package:nocturne/app/theme/nocturne_theme.dart';

/// Renders a primitive inside the real themes, delegates and directionality.
///
/// Every loading primitive reads tokens, typography and copy from the theme, so
/// testing one against a bare `MaterialApp` would prove nothing about how it
/// behaves in the app.
class LoadingHarness extends StatelessWidget {
  /// [reducedMotion] drives the same media query the browser preference does.
  const LoadingHarness({
    required this.child,
    this.themeMode = ThemeMode.dark,
    this.language = 'en',
    this.reducedMotion = false,
    this.viewportWidth = 800,
    super.key,
  });

  /// Widget under test.
  final Widget child;

  /// Which of the two artifacts to construct.
  final ThemeMode themeMode;

  /// Language code, which also decides text direction.
  final String language;

  /// Whether the viewer has asked for reduced motion.
  final bool reducedMotion;

  /// Width the type scale resolves against.
  final double viewportWidth;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    themeMode: themeMode,
    theme: DaybreakTheme.create(
      viewportWidth: viewportWidth,
      isArabic: language == 'ar',
    ),
    darkTheme: NocturneTheme.create(
      viewportWidth: viewportWidth,
      isArabic: language == 'ar',
    ),
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    // Applied inside the app so it survives the app's own media query.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: child ?? const SizedBox.shrink(),
    ),
    home: Scaffold(body: Center(child: child)),
  );
}
