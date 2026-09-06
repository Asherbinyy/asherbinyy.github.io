// @dart=3.9
// Freezed 2 emits final formal parameters; retain its supported syntax here.

import 'package:freezed_annotation/freezed_annotation.dart';

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
    String? role,
    String? metric,
    String? country,
    @Default(false) bool featured,
  }) = _ShippedApp;

  /// Decodes the documented JSON shape.
  factory ShippedApp.fromJson(Map<String, dynamic> json) =>
      _$ShippedAppFromJson(json);
}
