// @dart=3.9
// Freezed 2 emits final formal parameters; retain its supported syntax here.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:nocturne/content/models/localized_text.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// Identity and contact shared by the application and indexable pages.
@freezed
class Profile with _$Profile {
  /// Creates an immutable Profile record.
  const factory Profile({
    required LocalizedText name,
    required LocalizedText positioning,
    required Contact contact,
    LocalizedText? location,
    LocalizedText? status,
    Venture? venture,
    String? cvFile,
    Portrait? portrait,
    @Default(<ProfileStat>[]) List<ProfileStat> stats,
  }) = _Profile;

  /// Decodes the documented JSON shape.
  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}

/// One of the hero's instrument panels.
///
/// Owner-supplied rather than derived. The screen spec's panels read "25
/// shipped", "5 countries" and "4 years", and not one of those numbers is
/// computable from the content: the ledger lists the publicly linkable subset,
/// not everything delivered, and which roles count as commercial engineering is
/// a judgement only the owner can make. `AGENTS.md` section 3 forbids inventing
/// numbers, so an absent stats list renders no panels rather than a guess.
@freezed
class ProfileStat with _$ProfileStat {
  /// [value] is a string so "25+" and "4" are equally expressible.
  const factory ProfileStat({
    required String value,
    required LocalizedText label,
  }) = _ProfileStat;

  /// Decodes the documented JSON shape.
  factory ProfileStat.fromJson(Map<String, dynamic> json) =>
      _$ProfileStatFromJson(json);
}

/// Contact values supplied by the owner; optional links are omitted if missing.
@freezed
class Contact with _$Contact {
  /// Creates an immutable Contact record.
  const factory Contact({
    required String email,
    String? phone,
    Uri? linkedin,
    Uri? github,
    Uri? gitlab,
    Uri? medium,
    Uri? calendly,
  }) = _Contact;

  /// Decodes the documented JSON shape.
  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);
}

/// Qualified venture status; no claims are inferred from a project name.
@freezed
class Venture with _$Venture {
  /// Creates an immutable Venture record.
  const factory Venture({required LocalizedText label, Uri? url}) = _Venture;

  /// Decodes the documented JSON shape.
  factory Venture.fromJson(Map<String, dynamic> json) =>
      _$VentureFromJson(json);
}

/// Optional owner-provided portrait reference.
@freezed
class Portrait with _$Portrait {
  /// Creates an immutable Portrait record.
  const factory Portrait({required String src, required bool isPlaceholder}) =
      _Portrait;

  /// Decodes the documented JSON shape.
  factory Portrait.fromJson(Map<String, dynamic> json) =>
      _$PortraitFromJson(json);
}
