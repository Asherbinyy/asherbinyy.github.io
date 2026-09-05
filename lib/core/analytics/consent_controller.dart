import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/platform/preference_store.dart';

part 'consent_controller.g.dart';

/// Holds the viewer's consent decision and persists it.
///
/// Storing the decision itself is permitted without consent: a record of a
/// refusal is what makes the refusal durable, and re-asking on every visit
/// would be the dark pattern section 5 forbids. Nothing else about the viewer
/// is stored.
@Riverpod(keepAlive: true)
class ConsentController extends _$ConsentController {
  @override
  ConsentTier build() => ConsentTier.fromStorage(
    ref.watch(preferenceStoreProvider).read(PreferenceKey.consent.storageKey),
  );

  /// Grants session-scoped analytics.
  void grantSession() => _set(ConsentTier.session);

  /// Returns to aggregate-only counting.
  void withdrawToAggregate() => _set(ConsentTier.aggregate);

  /// Switches everything off for this viewer, Tier 0 included.
  void collectNothing() => _set(ConsentTier.none);

  void _set(ConsentTier value) {
    state = value;
    unawaited(
      ref
          .read(preferenceStoreProvider)
          .write(PreferenceKey.consent.storageKey, value.storageKey),
    );
  }
}
