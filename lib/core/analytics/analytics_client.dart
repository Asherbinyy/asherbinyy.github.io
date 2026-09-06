import 'package:nocturne/core/analytics/browser_analytics_context.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/events.dart';

/// Sends one beacon. Injected so no test ever reaches the network.
typedef BeaconSender = Future<void> Function(AnalyticsBeacon beacon);

/// The only thing on the site that may talk to the analytics endpoint.
///
/// A **hard no-op** until consent resolves, per section 4: not a queue that
/// flushes later — no data is captured at all before the grant. That
/// distinction matters, because a buffer that flushes on consent has still
/// collected from someone who had not agreed.
///
/// Tier 0 is the exception the regulation itself makes: aggregate, cookieless
/// counters that create no per-person record and write nothing to the device.
/// An explicit "collect nothing" switches even those off.
class AnalyticsClient {
  /// The transport is positional so it can stay private: a named parameter
  /// cannot be, and a public transport would let a caller send around the
  /// consent checks below.
  AnalyticsClient(this._send, {ConsentTier? tier, String Function()? sessionId})
    : tier = tier ?? ConsentTier.unresolved,
      _sessionId = sessionId ?? sessionIdForTab;

  final BeaconSender _send;

  /// The consent this client is operating under.
  ///
  /// Assigning it applies a decision immediately and within the same session:
  /// there is no buffer to drain on withdrawal, because nothing was buffered.
  ConsentTier tier;

  /// Records an event if — and only if — the current consent permits it.
  ///
  /// Returns whether anything was sent, so a test can assert silence rather
  /// than infer it.
  Future<bool> record(AnalyticsBeacon event) async {
    if (!permits(event.event)) return false;
    await _send(_identified(event));
    return true;
  }

  /// Attaches the tab's session identifier to Tier 1 events, and only those.
  ///
  /// Minting it here rather than at the call site is what guarantees no
  /// identifier can exist for a viewer who has not granted Tier 1: the only
  /// path to `sessionId()` runs through a tier check one line above.
  AnalyticsBeacon _identified(AnalyticsBeacon event) {
    if (!tier.allowsSessionEvents || event.event == AnalyticsEvent.routeView) {
      return event;
    }
    return (
      event: event.event,
      route: event.route,
      deviceClass: event.deviceClass,
      referrerHost: event.referrerHost,
      campaign: event.campaign,
      sessionId: event.sessionId ?? _sessionId(),
      value: event.value,
    );
  }

  /// Injected so a VM test can assert the identifier without a browser.
  final String Function() _sessionId;

  /// Whether [event] may be collected under the current tier.
  ///
  /// Public so `/how-it-was-built` can *measure* the rules rather than restate
  /// them: a second hand-written description of what is collected would be a
  /// claim about this code, and the two would eventually disagree.
  bool permits(AnalyticsEvent event) {
    if (!tier.allowsAggregate) return false;
    // Route views are the Tier 0 counter. Everything else is a session event
    // and needs an affirmative grant.
    if (event == AnalyticsEvent.routeView) return true;
    return tier.allowsSessionEvents;
  }
}
