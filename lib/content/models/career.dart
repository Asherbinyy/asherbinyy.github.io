// @dart=3.9
// Freezed 2 emits final formal parameters; retain its supported syntax here.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:nocturne/content/models/localized_text.dart';

part 'career.freezed.dart';
part 'career.g.dart';

/// Employment descriptions explicitly documented in the content schema.
enum EmploymentType {
  /// full-time as supplied by the content schema.
  @JsonValue('full-time')
  fullTime,

  /// full-time then part-time as supplied by the content schema.
  @JsonValue('full-time then part-time')
  fullTimeThenPartTime,
}

/// Chronological career transmissions. Incomplete copy stays absent.
@freezed
class Career with _$Career {
  /// Creates an immutable Career record.
  const factory Career({required List<CareerRole> roles}) = _Career;

  /// Decodes the documented JSON shape.
  factory Career.fromJson(Map<String, dynamic> json) => _$CareerFromJson(json);
}

/// A documented station with latitude/longitude and optional role details.
@freezed
class CareerRole with _$CareerRole {
  /// Creates an immutable CareerRole record.
  const factory CareerRole({
    required String id,
    required String country,
    required String city,
    required List<double> coords,
    required String start,
    String? end,
    String? company,
    LocalizedText? title,
    LocalizedText? summary,
    EmploymentType? employment,
    double? traceWeight,
    @Default(<String>[]) List<String> stack,
    @Default(<String>[]) List<String> appIds,
  }) = _CareerRole;

  /// Decodes the documented JSON shape.
  factory CareerRole.fromJson(Map<String, dynamic> json) =>
      _$CareerRoleFromJson(json);
}
