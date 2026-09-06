/// What the viewer has allowed.
///
/// `06-ANALYTICS-AND-PRIVACY.md` defines two tiers plus an explicit refusal.
/// Tier 0 is aggregate, cookieless and stores nothing on the device, so it sits
/// outside PECR consent; Tier 1 requires an affirmative action; and "collect
/// nothing" disables even Tier 0 for that viewer.
enum ConsentTier {
  /// The viewer has not yet chosen. Nothing beyond Tier 0 may run.
  unresolved('unresolved', 1),

  /// The viewer asked for nothing at all to be collected, Tier 0 included.
  none('none', 0),

  /// Aggregate, anonymous counters only.
  aggregate('aggregate', 1),

  /// Session-scoped events, granted explicitly.
  session('session', 2);

  const ConsentTier(this.storageKey, this.level);

  /// Stable key written to storage; never a display label.
  final String storageKey;

  /// How much this tier permits. Higher includes lower.
  final int level;

  /// Whether aggregate counters may be sent.
  ///
  /// Unresolved still permits them: Tier 0 creates no per-person record and
  /// writes nothing to the device, which is what puts it outside consent.
  /// Only an explicit refusal switches it off.
  bool get allowsAggregate => this != ConsentTier.none;

  /// Whether session-scoped events may be captured.
  bool get allowsSessionEvents => level >= ConsentTier.session.level;

  /// Whether the viewer has answered.
  bool get isResolved => this != ConsentTier.unresolved;

  /// Resolves a stored value, defaulting to unresolved.
  static ConsentTier fromStorage(String? value) => values.firstWhere(
    (tier) => tier.storageKey == value,
    orElse: () => ConsentTier.unresolved,
  );
}
