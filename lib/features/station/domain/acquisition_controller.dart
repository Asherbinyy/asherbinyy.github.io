import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'acquisition_controller.g.dart';

/// Whether the acquisition sequence has already played.
///
/// The screen spec says once per session. This is held in memory rather than in
/// storage: the sequence is not a preference the viewer chose, so writing it to
/// the device would be a storage write nobody asked for, and
/// `06-ANALYTICS-AND-PRIVACY.md` is explicit that nothing is written without a
/// reason. A hard reload therefore replays it, which is recorded as a known
/// divergence from "once per session".
@Riverpod(keepAlive: true)
class AcquisitionPlayed extends _$AcquisitionPlayed {
  @override
  bool build() => false;

  /// Marks the sequence complete, whether it ran or was skipped.
  void markPlayed() => state = true;
}
