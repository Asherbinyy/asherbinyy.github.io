import 'package:flutter/widgets.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/generated/app_localizations.dart';

/// Generated copy access for all future user-facing widgets.
extension LocalizationsContext on BuildContext {
  /// Resolves the active ARB channel from the app's localization delegates.
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// The content channel matching the interface language.
  ///
  /// Read from the same `Localizations` scope that resolves [l10n], so content
  /// and interface can never disagree about which language is on screen. The
  /// alternative — passing an `AppLocale` down to every widget that renders a
  /// `LocalizedText` — worked while only two screens needed it, and became
  /// prop-drilling through the ledger, the education table and every card once
  /// milestone 4 made the applications and the transcript translatable.
  ///
  /// Widgets that already receive a locale keep it. This is for the ones that
  /// would otherwise need one threaded through several layers of layout.
  AppLocale get channel =>
      Localizations.localeOf(this).languageCode == AppLocale.arabic.languageCode
      ? AppLocale.arabic
      : AppLocale.english;
}
