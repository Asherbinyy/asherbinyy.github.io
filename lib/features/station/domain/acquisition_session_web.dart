import 'dart:js_interop';

const _storageKey = 'nocturne.acquisition-played';
const _playedValue = '1';

@JS('window.sessionStorage.getItem')
external String? _getSessionItem(String key);

@JS('window.sessionStorage.setItem')
external void _setSessionItem(String key, String value);

/// Reads the functional once-per-tab marker.
bool hasPlayed() => _getSessionItem(_storageKey) == _playedValue;

/// The marker dies when the browser tab closes and carries no identity.
void markPlayed() => _setSessionItem(_storageKey, _playedValue);
