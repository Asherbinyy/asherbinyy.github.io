import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/browser_analytics_context.dart';
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
  ConsentTier build() {
    final store = ref.watch(preferenceStoreProvider);
    final decision = store.read(PreferenceKey.consent.storageKey);
    // Broader collection needs a fresh grant. An earlier rejection still holds.
    if (decision == null && store.read('nocturne.consent') == 'none') {
      return ConsentTier.none;
    }
    return ConsentTier.fromStorage(decision);
  }

  /// Grants session-scoped analytics.
  void grantSession() => _set(ConsentTier.session);

  /// Switches everything off for this viewer.
  void collectNothing() => _set(ConsentTier.none);

  void _set(ConsentTier value) {
    state = value;
    if (!value.allowsSessionEvents) clearAnalyticsSession();
    unawaited(
      ref
          .read(preferenceStoreProvider)
          .write(PreferenceKey.consent.storageKey, value.storageKey),
    );
  }
}
