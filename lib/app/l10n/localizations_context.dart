import 'package:flutter/widgets.dart';

import 'package:nocturne/app/l10n/generated/app_localizations.dart';

/// Generated copy access for all future user-facing widgets.
extension LocalizationsContext on BuildContext {
  /// Resolves the active ARB channel from the app's localization delegates.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
