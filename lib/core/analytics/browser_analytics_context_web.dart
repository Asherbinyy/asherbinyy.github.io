import 'dart:js_interop';

String? _campaign;

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
