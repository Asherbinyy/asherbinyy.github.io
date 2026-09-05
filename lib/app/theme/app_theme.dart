/// The two artifacts, named as the design system names them.
///
/// A pure-Dart enum rather than Material's `ThemeMode` so the generated
/// controller never has to summarise a Flutter type, and so "system" — which
/// this site does not offer, because dark is the identity rather than a mode —
/// is not representable.
enum AppTheme {
  /// The primary, dark artifact.
  nocturne('nocturne'),

  /// The secondary artifact: a technical drawing on paper.
  daybreak('daybreak');

  const AppTheme(this.storageKey);

  /// Stable key written to storage; never a display label.
  final String storageKey;

  /// The other artifact, for a toggle.
  AppTheme get opposite =>
      this == AppTheme.nocturne ? AppTheme.daybreak : AppTheme.nocturne;

  /// Resolves a stored value, falling back to the identity theme.
  static AppTheme fromStorage(String? value) => values.firstWhere(
    (theme) => theme.storageKey == value,
    orElse: () => AppTheme.nocturne,
  );
}
