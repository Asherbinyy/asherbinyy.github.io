/// Synchronous read, asynchronous write, so a preference can be applied on the
/// first frame without the app waiting on storage.
///
/// An interface rather than a direct `shared_preferences` call so the
/// controllers stay pure Dart — the code generator cannot summarise Flutter
/// plugin types — and so tests can drive persistence without a real store.
abstract interface class PreferenceStore {
  /// The stored value for [key], or null when nothing was written.
  String? read(String key);

  /// Persists [value] under [key].
  Future<void> write(String key, String value);

  /// Forgets [key] entirely.
  ///
  /// Not the same as writing an empty value. A viewer who asks to be forgotten
  /// should leave nothing behind that says they were ever here, including a
  /// key holding the word "none".
  Future<void> remove(String key);
}

/// The default store: nothing survives a reload.
///
/// Used by tests and as the fallback before the real store has loaded. It is
/// deliberately the default so that forgetting to install the real store
/// degrades to no persistence rather than to a crash.
class InMemoryPreferenceStore implements PreferenceStore {
  /// Starts empty unless [seed] supplies existing values.
  InMemoryPreferenceStore([Map<String, String>? seed]) : _values = {...?seed};

  final Map<String, String> _values;

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}

/// Keys owned by this store.
///
/// These hold choices the viewer made deliberately — a theme, a language, a
/// display mode. UK PECR exempts storage that is strictly necessary for a
/// service the user explicitly requested, and the ICO names user-interface
/// customisation as an example, so these are written without a consent gate.
/// `06-ANALYTICS-AND-PRIVACY.md` section 3's prohibition on device storage
/// governs analytics identifiers, which are a different thing entirely and
/// must never be written here.
enum PreferenceKey {
  /// Which of the two artifacts the viewer chose.
  theme('nocturne.theme'),

  /// Which language channel the viewer chose.
  language('nocturne.language'),

  /// Whether the viewer turned on Recruiter Mode.
  recruiterMode('nocturne.recruiterMode'),

  /// The viewer's consent decision.
  ///
  /// Storing the decision is what makes a refusal durable; re-asking on every
  /// visit would be the dark pattern `06-ANALYTICS-AND-PRIVACY.md` section 5
  /// forbids. No identifier accompanies it, and no session id is ever written
  /// here or anywhere else on the device.
  consent('nocturne.consent'),

  /// Whether the viewer joined the climb's leaderboard, and under what name.
  ///
  /// This one holds an identifier, which every other key here deliberately
  /// does not, so the line it sits on the right side of is worth stating.
  /// Section 3's prohibition governs **analytics** identifiers: a value written
  /// so that a visitor can be counted or followed. This is the opposite kind of
  /// thing. It is a random value the visitor's own browser made at the moment
  /// they asked to be on a public scoreboard, it exists so their next climb can
  /// replace their own entry rather than add a second one, and without it the
  /// feature they asked for cannot work at all -- which is the strictly
  /// necessary exemption this enum's own note already relies on.
  ///
  /// It is written only after an explicit choice, never on merely playing, and
  /// `forget` removes both it and the entry it points at.
  gameParticipation('nocturne.game.participation');

  const PreferenceKey(this.storageKey);

  /// The literal key written to storage.
  final String storageKey;
}
