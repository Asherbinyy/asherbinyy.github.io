import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/router.dart';
import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/theme/app_theme.dart';
import 'package:nocturne/app/theme/daybreak_theme.dart';
import 'package:nocturne/app/theme/nocturne_theme.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/platform_provider.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';

/// The title the hand-authored shell in `web/index.html` already carries.
///
/// Kept in step with that file by a test rather than by memory: a tab that
/// disagrees with the document it replaced reads as carelessness.
const String shellTitle = 'Ahmed Elsherbini — Mobile Engineer, Manchester';

/// The app shell. Theme, language and Recruiter Mode are driven by controllers.
class NocturneApp extends ConsumerStatefulWidget {
  /// Explicit inputs allow testing both artifacts without touching storage.
  const NocturneApp({this.themeMode, this.locale, super.key});

  /// Optional host override; otherwise the persisted theme controller wins.
  final ThemeMode? themeMode;

  /// Optional host override; otherwise the in-memory language controller wins.
  final Locale? locale;

  @override
  ConsumerState<NocturneApp> createState() => _NocturneAppState();
}

class _NocturneAppState extends ConsumerState<NocturneApp> {
  final GoRouter _router = AppRouter.create();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale =
        widget.locale ??
        Locale(ref.watch(localeControllerProvider).languageCode);
    final themeMode =
        widget.themeMode ??
        switch (ref.watch(themeControllerProvider)) {
          AppTheme.nocturne => ThemeMode.dark,
          AppTheme.daybreak => ThemeMode.light,
        };
    final capabilities =
        ref.watch(platformCapabilitiesProvider).valueOrNull ??
        const PointerCapabilities();
    return LayoutBuilder(
      builder: (context, constraints) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        // `WidgetsApp` mounts its own `Title` and defaults it to the empty
        // string, which does not leave `document.title` alone — it overwrites
        // it. Without this the hand-authored title in `web/index.html` was
        // erased on first build and the tab sat blank until content resolved,
        // which is what the deployed /writing page was observed doing.
        //
        // The same words as the shell's static title, so nothing flickers
        // between the document loading and Flutter taking over.
        title: shellTitle,
        routerConfig: _router,
        themeMode: themeMode,
        themeAnimationDuration: Tokens.noMotion,
        theme: DaybreakTheme.create(
          viewportWidth: constraints.maxWidth,
          isArabic: locale.languageCode == 'ar',
        ),
        darkTheme: NocturneTheme.create(
          viewportWidth: constraints.maxWidth,
          isArabic: locale.languageCode == 'ar',
        ),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        // The SDK's generated aggregate delegates use legacy Material types.
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        builder: (context, child) => PlatformScope(
          service: PlatformService(
            capabilities: capabilities,
            viewportWidth: constraints.maxWidth,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
