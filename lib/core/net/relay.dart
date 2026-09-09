import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one outbound origin this app talks to.
///
/// **This is content, not analytics, and it must not share a switch with it.**
/// The writing endpoint used to be derived from `ANALYTICS_ENDPOINT`, and the
/// release build deliberately supplies none, because the site collects
/// nothing. The consequence was that turning collection off also turned the
/// owner's articles off, and `/writing` shipped empty for weeks.
///
/// The two were conflated because they happen to live on the same Worker. That
/// is a deployment detail, not a reason to couple them: a request to
/// `/v1/writing` carries nothing about the viewer, because the Worker fetches
/// Medium itself, which is exactly why it needs no consent and no opt-in.
///
/// Lifted out of the writing feature, which defined it because it was the
/// first thing to need it. It is not a writing concern: the same origin serves
/// the article feed, the cover relay and the content the owner publishes from
/// the admin panel, and the content layer cannot reach into a feature to find
/// out where it lives.
///
/// The default is the deployed relay. An override exists for a different
/// deployment, and an explicitly empty value silences everything that depends
/// on it, but a build that says nothing gets the relay.
const String _relayDefault =
    'https://nocturne-analytics.asherbinyy.workers.dev';

/// The relay's origin, overridable at build time.
final relayEndpointProvider = Provider<Uri?>((ref) {
  const value = String.fromEnvironment(
    'WRITING_RELAY',
    defaultValue: _relayDefault,
  );
  if (value.isEmpty) return null;
  final parsed = Uri.tryParse(value);
  // https only, and a host: this is the one outbound origin the app talks to.
  if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) {
    return null;
  }
  return parsed;
});
