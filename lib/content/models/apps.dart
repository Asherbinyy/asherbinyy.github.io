// @dart=3.9
// Freezed 2 emits final formal parameters; retain its supported syntax here.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:nocturne/content/models/localized_text.dart';

part 'apps.freezed.dart';
part 'apps.g.dart';

/// Store destinations describe shipped apps, not this web app's target.
enum AppPlatform {
  /// Apple App Store destination.
  ios,

  /// Google Play destination.
  android,
}

/// Work domains present in the owner's documented ledger.
enum WorkDomain {
  /// Travel as supplied by the content schema.
  @JsonValue('Travel')
  travel,

  /// Mobility as supplied by the content schema.
  @JsonValue('Mobility')
  mobility,

  /// Education as supplied by the content schema.
  @JsonValue('Education')
  education,

  /// Retail as supplied by the content schema.
  @JsonValue('Retail')
  retail,

  /// Services as supplied by the content schema.
  @JsonValue('Services')
  services,

  /// Marketplace as supplied by the content schema.
  @JsonValue('Marketplace')
  marketplace,

  /// Consumer as supplied by the content schema.
  @JsonValue('Consumer')
  consumer,

  /// Safety as supplied by the content schema.
  @JsonValue('Safety')
  safety,
}

/// How the owner was engaged on a piece of work.
///
/// Absent where the content does not say. Present on the freelance work
/// because "shipped 25+ applications" reads differently once a reader can see
/// which of them he was hired directly to build, and that distinction is the
/// owner's to claim rather than one a reader should have to infer.
enum Engagement {
  /// Engaged directly by the client, outside any employer.
  @JsonValue('freelance')
  freelance,

  /// Fixed-term engagement through a company.
  @JsonValue('contract')
  contract,
}

/// Applications in source order; featured membership drives Recruiter Mode.
@freezed
class Apps with _$Apps {
  /// Creates an immutable Apps record.
  const factory Apps({required List<ShippedApp> apps}) = _Apps;

  /// Decodes the documented JSON shape.
  factory Apps.fromJson(Map<String, dynamic> json) => _$AppsFromJson(json);
}

/// An application record; absent metrics and links remain absent.
@freezed
class ShippedApp with _$ShippedApp {
  /// Creates an immutable ShippedApp record.
  const factory ShippedApp({
    required String id,
    required String name,
    required List<AppPlatform> platforms,
    required Map<AppPlatform, Uri> store,
    required WorkDomain domain,
    LocalizedText? role,
    String? metric,
    String? country,
    Engagement? engagement,
    @Default(false) bool featured,
  }) = _ShippedApp;

  /// Decodes the documented JSON shape.
  factory ShippedApp.fromJson(Map<String, dynamic> json) =>
      _$ShippedAppFromJson(json);
}
