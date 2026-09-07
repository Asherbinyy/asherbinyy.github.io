// @dart=3.9
// Freezed 2 emits final formal parameters; retain its supported syntax here.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:nocturne/content/models/localized_text.dart';

part 'education.freezed.dart';
part 'education.g.dart';

/// Supplied qualifications; absence of a status does not imply graduation.
@freezed
class Education with _$Education {
  /// Creates an immutable Education record.
  const factory Education({required List<EducationEntry> entries}) = _Education;

  /// Decodes the documented JSON shape.
  factory Education.fromJson(Map<String, dynamic> json) =>
      _$EducationFromJson(json);
}

/// Marks are preserved as supplied; presentation decides which are publishable.
@freezed
class EducationEntry with _$EducationEntry {
  /// Creates an immutable EducationEntry record.
  const factory EducationEntry({
    required LocalizedText institution,
    required LocalizedText award,
    required String start,
    required String end,
    LocalizedText? status,
    double? overallMark,
    @Default(<EducationModule>[]) List<EducationModule> modules,
    @Default(<LocalizedText>[]) List<LocalizedText> highlights,
  }) = _EducationEntry;

  /// Decodes the documented JSON shape.
  factory EducationEntry.fromJson(Map<String, dynamic> json) =>
      _$EducationEntryFromJson(json);
}

/// One transcript module and its supplied percentage mark.
@freezed
class EducationModule with _$EducationModule {
  /// Creates an immutable EducationModule record.
  const factory EducationModule({
    required LocalizedText name,
    required double mark,
    Evidence? evidence,
  }) = _EducationModule;

  /// Decodes the documented JSON shape.
  factory EducationModule.fromJson(Map<String, dynamic> json) =>
      _$EducationModuleFromJson(json);
}

/// A piece of coursework the owner is willing to show.
///
/// A mark is a number the reader has to take on trust. The artefact behind it
/// is the thing that makes it evidence rather than a claim, which is the whole
/// argument of `14-PROVENANCE.md` applied to the transcript.
///
/// Absent on every module where the owner has not supplied one, and nothing
/// is inferred: a module without evidence renders its mark exactly as before.
@freezed
class Evidence with _$Evidence {
  /// Creates an immutable Evidence record.
  const factory Evidence({
    required String src,
    required LocalizedText caption,
  }) = _Evidence;

  /// Decodes the documented JSON shape.
  factory Evidence.fromJson(Map<String, dynamic> json) =>
      _$EvidenceFromJson(json);
}
