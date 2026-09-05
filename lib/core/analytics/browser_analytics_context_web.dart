import 'dart:js_interop';

const _campaignKey = 'nocturne.campaign';

@JS('window.sessionStorage.setItem')
external void _setSessionItem(String key, String value);

@JS('window.sessionStorage.getItem')
external String? _getSessionItem(String key);

@JS('document.referrer')
external String get _documentReferrer;

/// Campaign attribution is session-scoped and contains no viewer identifier.
void captureCampaign(String campaign) =>
    _setSessionItem(_campaignKey, campaign);

/// Returns the campaign captured on entry to this tab.
String? currentCampaign() => _getSessionItem(_campaignKey);

/// Parses only the host, dropping path, query and fragment at this boundary.
String? currentReferrerHost() {
  final referrer = Uri.tryParse(_documentReferrer);
  return referrer == null || referrer.host.isEmpty ? null : referrer.host;
}
