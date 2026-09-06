/// Browser media-query results, independent of operating system and width.
class PointerCapabilities {
  /// Defaults represent inconclusive capabilities, including the VM test host.
  const PointerCapabilities({
    this.canHover = false,
    this.hasFinePointer = false,
    this.hasCoarsePointer = false,
  });

  /// The primary pointer can hover.
  final bool canHover;

  /// The primary pointer is precise.
  final bool hasFinePointer;

  /// The primary pointer is coarse.
  final bool hasCoarsePointer;
}
