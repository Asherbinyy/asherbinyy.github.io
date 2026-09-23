import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nocturne/core/net/relay.dart';

/// Resolve uploaded bytes through the configured first-party content relay.
/// Bundle paths remain assets; arbitrary remote URLs are never accepted here.
ImageProvider<Object> contentImage(BuildContext context, String source) {
  final endpoint = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(relayEndpointProvider);
  if (RegExp(r'^/v1/media/[0-9a-f]{32}$').hasMatch(source) &&
      endpoint != null) {
    return NetworkImage(endpoint.resolve(source).toString());
  }
  return AssetImage(source);
}
