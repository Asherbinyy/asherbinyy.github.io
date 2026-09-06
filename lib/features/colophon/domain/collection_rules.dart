import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/events.dart';

/// One row of the collection readout: an event, and the tier it needs.
typedef CollectionRule = ({AnalyticsEvent event, ConsentTier requires});

/// What is collected at each tier, derived from the client that enforces it.
///
/// `06-ANALYTICS-AND-PRIVACY.md`'s addendum reassigned the detailed readout
/// from `/privacy` to this page, where it demonstrates the pipeline to somebody
/// who came to read about it rather than confronting a visitor with a data
/// dashboard.
///
/// **Derived by asking the real client, not by describing it.** A second
/// hand-written list of the rules would be a claim about the code; probing
/// `AnalyticsClient` at each tier is a measurement of it, and the two cannot
/// drift apart. A test asserts the readout matches actual behaviour, which is
/// what §9 requires of it.
List<CollectionRule> collectionRules() {
  final rules = <CollectionRule>[];
  for (final event in AnalyticsEvent.values) {
    rules.add((event: event, requires: _lowestTierAllowing(event)));
  }
  return List.unmodifiable(rules);
}

/// The weakest consent under which [event] is actually sent.
ConsentTier _lowestTierAllowing(AnalyticsEvent event) {
  for (final tier in [
    ConsentTier.none,
    ConsentTier.unresolved,
    ConsentTier.aggregate,
    ConsentTier.session,
  ]) {
    if (_permits(tier, event)) return tier;
  }
  return ConsentTier.session;
}

/// Asks a real client whether it would permit the event at this tier.
///
/// The client is the thing that enforces consent, so asking it is a
/// measurement. The transport never runs: `permits` is the same check `record`
/// consults one line before sending, exposed rather than duplicated.
bool _permits(ConsentTier tier, AnalyticsEvent event) =>
    AnalyticsClient((_) async {}, tier: tier).permits(event);
