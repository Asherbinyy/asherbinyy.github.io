import 'package:nocturne/app/l10n/app_locale.dart';

/// The names behind the two-letter codes the content stores.
///
/// The content keeps ISO 3166-1 alpha-2 because that is what the map, the
/// career and the reach row all key on, and a code is the stable thing. But
/// "QA" is not a place to a reader, so anywhere a country is shown to a person
/// rather than to the atlas, it is named here.
///
/// These are the countries' own standard names, not a translation of anything
/// the owner wrote: no claim about him is being made by either column. A code
/// with no entry falls back to the code itself rather than to a guess.
abstract final class CountryNames {
  static const Map<String, (String en, String ar)> _names = {
    'AM': ('Armenia', 'أرمينيا'),
    'CA': ('Canada', 'كندا'),
    'EG': ('Egypt', 'مصر'),
    'GB': ('United Kingdom', 'المملكة المتحدة'),
    'QA': ('Qatar', 'قطر'),
    'RU': ('Russia', 'روسيا'),
    'SA': ('Saudi Arabia', 'السعودية'),
  };

  /// The country's name in [locale], or the code where it is not known.
  static String of(String code, AppLocale locale) {
    final entry = _names[code.toUpperCase()];
    if (entry == null) return code;
    return locale == AppLocale.arabic ? entry.$2 : entry.$1;
  }

  /// Whether a code has a name at all.
  static bool knows(String code) => _names.containsKey(code.toUpperCase());
}
