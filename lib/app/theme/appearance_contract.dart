import 'package:nocturne/app/theme/app_theme.dart';

/// The renderers this build knows how to draw, and what to do about the rest.
///
/// The admin panel lets the owner store an appearance against the site, and
/// the app has to read it back. Those are two programs that ship separately,
/// so at some point the panel will offer something this build has never heard
/// of — a renderer added after the app was deployed, a value typed by hand, a
/// stale draft from before something was withdrawn.
///
/// The tempting answer is to fall back to the default and carry on. That is
/// the wrong answer: it makes an unsupported appearance indistinguishable from
/// the supported one, so the owner picks something, sees the site unchanged,
/// and cannot tell whether it failed or whether it simply looks like that. The
/// contract says such a value is **reported as unsupported**, and this is where
/// that decision lives.
///
/// The list is versioned because the admin side has to agree with it. Bump
/// [version] whenever an id is added or withdrawn, and mirror the change in
/// `worker/contracts/appearance.js`; the shared fixture holds both to it.
abstract final class AppearanceContract {
  /// The generation of this allowlist.
  static const int version = 1;

  /// Every renderer this build can draw, by stored id.
  ///
  /// Deliberately the two that exist. The handoff is explicit that no
  /// unrequested presets are to be invented while the controls are wired, so
  /// this is a list of what is real rather than a list of what is possible.
  static const Map<String, AppTheme> supported = {
    'nocturne': AppTheme.nocturne,
    'daybreak': AppTheme.daybreak,
  };

  /// Whether [id] names a renderer this build can draw.
  static bool supports(String? id) => supported.containsKey(id);

  /// Reads a stored id, or explains why it cannot be used.
  ///
  /// Never guesses. A null id is not an error — it means nothing has been
  /// chosen, and the app's own default applies — but a *present* id that is
  /// not on the list is a mismatch worth surfacing.
  static AppearanceResolution resolve(String? id) {
    if (id == null || id.isEmpty) {
      return const AppearanceResolution.unset();
    }
    final theme = supported[id];
    if (theme == null) return AppearanceResolution.unsupported(id);
    return AppearanceResolution.supported(theme, id);
  }
}

/// What reading a stored appearance id produced.
sealed class AppearanceResolution {
  const AppearanceResolution();

  /// Nothing is stored; the app's own default stands.
  const factory AppearanceResolution.unset() = AppearanceUnset;

  /// A renderer this build can draw.
  const factory AppearanceResolution.supported(AppTheme theme, String id) =
      AppearanceSupported;

  /// A renderer this build has never heard of.
  const factory AppearanceResolution.unsupported(String id) =
      AppearanceUnsupported;
}

/// No appearance has been chosen.
final class AppearanceUnset extends AppearanceResolution {
  /// Creates the unset resolution.
  const AppearanceUnset();
}

/// The stored id names a renderer this build can draw.
final class AppearanceSupported extends AppearanceResolution {
  /// Creates a supported resolution.
  const AppearanceSupported(this.theme, this.id);

  /// The renderer to use.
  final AppTheme theme;

  /// The id it was stored under.
  final String id;
}

/// The stored id is not one this build knows.
///
/// Carries the id rather than discarding it, so whatever reports this can say
/// *which* value it could not use. "Unsupported appearance" is a shrug;
/// "unsupported appearance: papyrus-v2" is something the owner can act on.
final class AppearanceUnsupported extends AppearanceResolution {
  /// Creates an unsupported resolution.
  const AppearanceUnsupported(this.id);

  /// The id that was stored.
  final String id;
}
