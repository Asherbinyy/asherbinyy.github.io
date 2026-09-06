import 'dart:math';

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

/// This tab's Tier 1 session identifier, minted on first use.
///
/// Random, not derived: nothing about the viewer, their address or their agent
/// contributes to it, so it identifies a tab and nothing else. It is only ever
/// requested once consent has resolved to Tier 1 — the client is what enforces
/// that, and this function is what makes the identifier tab-scoped.
String sessionIdForTab({Random? random}) {
  final existing = browser.readSessionId();
  if (existing != null && existing.isNotEmpty) return existing;

  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  final id = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  browser.writeSessionId(id);
  return id;
}
