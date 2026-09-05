// @dart=3.9
// Freezed 2 emits final formal parameters; retain its supported syntax here.

import 'package:freezed_annotation/freezed_annotation.dart';

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
    required String institution,
    required String award,
    required String start,
    required String end,
    String? status,
    double? overallMark,
    @Default(<EducationModule>[]) List<EducationModule> modules,
    @Default(<String>[]) List<String> highlights,
  }) = _EducationEntry;

  /// Decodes the documented JSON shape.
  factory EducationEntry.fromJson(Map<String, dynamic> json) =>
      _$EducationEntryFromJson(json);
}

/// One transcript module and its supplied percentage mark.
@freezed
class EducationModule with _$EducationModule {
  /// Creates an immutable EducationModule record.
  const factory EducationModule({required String name, required double mark}) =
      _EducationModule;

  /// Decodes the documented JSON shape.
  factory EducationModule.fromJson(Map<String, dynamic> json) =>
      _$EducationModuleFromJson(json);
}
