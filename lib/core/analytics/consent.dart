/// What the viewer has allowed.
///
/// Both aggregate views and interaction events require an affirmative grant.
/// An unresolved choice and a rejection send nothing.
enum ConsentTier {
  /// The viewer has not yet chosen. No analytics may run.
  unresolved('unresolved'),

  /// The viewer asked for nothing to be collected.
  none('none'),

  /// Session-scoped events, granted explicitly.
  session('session');

  const ConsentTier(this.storageKey);

  /// Stable key written to storage; never a display label.
  final String storageKey;

  /// Whether aggregate counters may be sent.
  bool get allowsAggregate => this == ConsentTier.session;

  /// Whether session-scoped events may be captured.
  bool get allowsSessionEvents => this == ConsentTier.session;

  /// Whether the viewer has answered.
  bool get isResolved => this != ConsentTier.unresolved;

  /// Resolves a stored value, defaulting to unresolved.
  static ConsentTier fromStorage(String? value) => values.firstWhere(
    (tier) => tier.storageKey == value,
    orElse: () => ConsentTier.unresolved,
  );
}
