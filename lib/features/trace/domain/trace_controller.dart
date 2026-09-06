import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/features/trace/domain/trace_state.dart';

part 'trace_controller.g.dart';

/// Publishes the current trace state for the rail to read.
///
/// Task 1.5 needs a truthful value for the rail indicator; task 1.7 replaces
/// the body with the scroll-velocity state machine described in
/// `02-SCREEN-SPECS.md`. It rests at standby, which is the honest reading
/// while nothing is scrolling.
@Riverpod(keepAlive: true)
class TraceController extends _$TraceController {
  @override
  TraceState build() => TraceState.standby;

  /// The current state, for imperative callers; widgets watch the provider.
  TraceState get current => state;

  /// Sets the current state. Driven by the trace painter from task 1.7.
  set current(TraceState value) => state = value;
}
