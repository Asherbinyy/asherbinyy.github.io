// @dart=3.9
// Freezed 2 emits final formal parameters; retain its supported syntax here.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:nocturne/app/l10n/app_locale.dart';

part 'localized_text.freezed.dart';
part 'localized_text.g.dart';

/// Supplied English copy with optional, owner-supplied Arabic translation.
@freezed
class LocalizedText with _$LocalizedText {
  /// Creates an immutable LocalizedText record.
  const factory LocalizedText({required String en, String? ar}) =
      _LocalizedText;
  const LocalizedText._();

  /// Decodes the documented JSON shape.
  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      _$LocalizedTextFromJson(json);

  /// Missing translations use the supplied English, never invented Arabic.
  String resolve(AppLocale locale) => switch (locale) {
    AppLocale.english => en,
    AppLocale.arabic => ar ?? en,
  };
}
