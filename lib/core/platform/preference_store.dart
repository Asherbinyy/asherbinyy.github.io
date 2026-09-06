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
  consent('nocturne.consent');

  const PreferenceKey(this.storageKey);

  /// The literal key written to storage.
  final String storageKey;
}
