// @dart=3.9
// Freezed 2 emits final formal parameters; retain its supported syntax here.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:nocturne/content/models/localized_text.dart';

part 'study.freezed.dart';
part 'study.g.dart';

/// Owner-authored case study narrative; schema only until copy is supplied.
@freezed
class Study with _$Study {
  /// Creates an immutable Study record.
  const factory Study({
    required String id,
    required LocalizedText title,
    required LocalizedText context,
    required LocalizedText problem,
    required LocalizedText approach,
    required LocalizedText outcome,
    required List<String> stack,
    required List<StudyScreen> screens,
  }) = _Study;

  /// Decodes the documented JSON shape.
  factory Study.fromJson(Map<String, dynamic> json) => _$StudyFromJson(json);
}

/// Screenshot reference with bilingual caption.
@freezed
class StudyScreen with _$StudyScreen {
  /// Creates an immutable StudyScreen record.
  const factory StudyScreen({
    required String src,
    required LocalizedText caption,
  }) = _StudyScreen;

  /// Decodes the documented JSON shape.
  factory StudyScreen.fromJson(Map<String, dynamic> json) =>
      _$StudyScreenFromJson(json);
}
