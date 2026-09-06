/// Supported content channels, independent of Flutter for code generation.
enum AppLocale {
  /// Default channel until the visitor explicitly selects Arabic.
  english('en'),

  /// Arabic uses RTL layout and the Arabic typography metrics.
  arabic('ar');

  const AppLocale(this.languageCode);

  /// Language code shared by ARB files, content, and Flutter locales.
  final String languageCode;
}
