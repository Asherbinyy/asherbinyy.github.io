import 'package:nocturne/core/analytics/browser_analytics_context_stub.dart'
    if (dart.library.js_interop) 'package:nocturne/core/analytics/browser_analytics_context_web.dart'
    as browser;

/// Stores an owner-defined campaign slug for this browser tab only.
void captureCampaign(String? campaign) {
  if (campaign == null ||
      !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(campaign)) {
    return;
  }
  browser.captureCampaign(campaign);
}

/// The campaign associated with this tab, if entry used `/r/:campaign`.
String? currentCampaign() => browser.currentCampaign();

/// Referrer host only; paths and query parameters never leave the browser.
String? currentReferrerHost() => browser.currentReferrerHost();
