import 'package:shared_preferences/shared_preferences.dart';

import 'package:nocturne/core/platform/preference_store.dart';

/// The real store, backed by the browser's local storage.
///
/// Kept out of `preference_store.dart` so the controllers depend on the
/// interface alone and the code generator never has to summarise the plugin.
class SharedPreferenceStore implements PreferenceStore {
  /// Wraps an instance already loaded at bootstrap, so reads are synchronous
  /// and the first frame renders with the viewer's choices already applied.
  const SharedPreferenceStore(this._preferences);

  /// Loads the underlying instance. Call once, before `runApp`.
  static Future<SharedPreferenceStore> load() async =>
      SharedPreferenceStore(await SharedPreferences.getInstance());

  final SharedPreferences _preferences;

  @override
  String? read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}
