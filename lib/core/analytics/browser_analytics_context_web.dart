import 'dart:js_interop';

const _campaignKey = 'nocturne.campaign';
const _sessionKey = 'nocturne.session';
String? _campaign;
String? _session;

@JS('window.sessionStorage.setItem')
external void _setSessionItem(String key, String value);

@JS('window.sessionStorage.getItem')
external String? _getSessionItem(String key);

@JS('document.referrer')
external String get _documentReferrer;

/// Campaign attribution is session-scoped and contains no viewer identifier.
void captureCampaign(String campaign) {
  _campaign = campaign;
}

/// Returns the campaign captured on entry to this tab.
String? currentCampaign() => _campaign;

/// Parses only the host, dropping path, query and fragment at this boundary.
String? currentReferrerHost() {
  final referrer = Uri.tryParse(_documentReferrer);
  return referrer == null || referrer.host.isEmpty ? null : referrer.host;
}

/// Reads this tab's session identifier, if one has been issued.
///
/// `sessionStorage`, never `localStorage`: section 4 requires the identifier to
/// die with the tab and never be linked across visits. There is a mandatory
/// test asserting nothing is written to `localStorage`.
String? readSessionId() {
  try {
    return _session ??= _getSessionItem(_sessionKey);
  } on Object {
    return _session;
  }
}

/// Stores this tab's session identifier for the life of the tab.
void writeSessionId(String id) {
  _session = id;
  try {
    _setSessionItem(_sessionKey, id);
  } on Object {
    // A denied storage API must not break the visitor's chosen collection.
  }
}

@JS('window.sessionStorage.removeItem')
external void _removeSessionItem(String key);

/// Withdrawal removes the tab identifier and any legacy campaign entry.
void clearAnalyticsSession() {
  _session = null;
  try {
    _removeSessionItem(_sessionKey);
    _removeSessionItem(_campaignKey);
  } on Object {
    /* Storage may be disabled by the browser. */
  }
}
