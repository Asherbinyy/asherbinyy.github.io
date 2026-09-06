import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/features/station/domain/acquisition_session.dart';

part 'acquisition_controller.g.dart';

/// Whether the acquisition sequence has already played.
///
/// Browser builds seed this from a functional `sessionStorage` flag, so a hard
/// reload in the same tab does not replay the sequence. The flag dies with the
/// tab, carries no identity and is unrelated to analytics consent.
@Riverpod(keepAlive: true)
class AcquisitionPlayed extends _$AcquisitionPlayed {
  @override
  bool build() => hasPlayedAcquisition();

  /// Marks the sequence complete, whether it ran or was skipped.
  void markPlayed() {
    markAcquisitionPlayed();
    state = true;
  }
}
