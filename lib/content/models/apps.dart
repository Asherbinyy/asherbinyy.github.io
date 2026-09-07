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

  /// pub.dev destination.
  ///
  /// A package rather than an application, which is why it needed its own
  /// value: it has a public listing anyone can open, which is the owner's
  /// rule for what ships, but it is not something a person installs on a
  /// phone. The ledger says "pub.dev" beside it rather than a store name.
  pub,
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

  /// Open source as supplied by the content schema.
  @JsonValue('Open source')
  openSource,
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
///
/// [screenshot] is a path into `assets/media/apps/`. Where it is absent the
/// row draws the procedural station card instead, which is a designed
/// treatment rather than a gap — so the ledger looks finished whether the
/// owner has supplied a screenshot or not, and supplying one is a one-line
/// content edit rather than a code change. Convention in
/// `assets/media/apps/README.md`.
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
    String? screenshot,
    @Default(false) bool featured,
  }) = _ShippedApp;

  /// Decodes the documented JSON shape.
  factory ShippedApp.fromJson(Map<String, dynamic> json) =>
      _$ShippedAppFromJson(json);
}
