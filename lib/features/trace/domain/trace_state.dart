/// The three trace states from `02-SCREEN-SPECS.md`.
///
/// Declared here in Milestone 1 task 1.5 because the rail carries the state
/// indicator and must render something truthful before the trace exists. Task
/// 1.7 owns the velocity thresholds that drive the transitions; this owns only
/// the vocabulary, so the rail is not rewritten when the trace lands.
enum TraceState {
  /// No scroll for at least 1.2s. The rail reads standby.
  standby,

  /// Scrolling faster than the coherence threshold. The rail reads scanning.
  scanning,

  /// Slow enough, and near a burst. The rail reads lock, in amber.
  lock;

  /// Whether the rail should render this state in `--beacon`.
  ///
  /// Only lock earns the amber: it is the moment the site rewards slowing
  /// down, and highlighting the other two would spend the one chroma on
  /// states that mean nothing happened.
  bool get isHighlighted => this == TraceState.lock;
}
