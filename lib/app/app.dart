import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/router.dart';
import 'package:nocturne/app/theme/daybreak_theme.dart';
import 'package:nocturne/app/theme/nocturne_theme.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/platform_provider.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';

/// Empty foundation app; locale and theme controls belong to later tasks.
class NocturneApp extends ConsumerStatefulWidget {
  /// Explicit inputs allow testing both artifacts without persistence.
  const NocturneApp({
    this.themeMode = ThemeMode.dark,
    this.locale = const Locale('en'),
    super.key,
  });

  /// Active theme, defaulting to the Nocturne identity.
  final ThemeMode themeMode;

  /// Locale controls metrics and direction, without inventing translated copy.
  final Locale locale;

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
    final capabilities =
        ref.watch(platformCapabilitiesProvider).valueOrNull ??
        const PointerCapabilities();
    return LayoutBuilder(
      builder: (context, constraints) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        themeMode: widget.themeMode,
        themeAnimationDuration: Tokens.noMotion,
        theme: DaybreakTheme.create(
          viewportWidth: constraints.maxWidth,
          isArabic: widget.locale.languageCode == 'ar',
        ),
        darkTheme: NocturneTheme.create(
          viewportWidth: constraints.maxWidth,
          isArabic: widget.locale.languageCode == 'ar',
        ),
        locale: widget.locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
