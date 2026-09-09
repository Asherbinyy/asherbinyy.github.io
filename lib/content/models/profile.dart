// @dart=3.9
// Freezed 2 emits final formal parameters; retain its supported syntax here.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:nocturne/content/models/localized_text.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// Identity and contact shared by the application and indexable pages.
///
/// [name] is the legal name and [displayName] is what the owner is called.
/// They are separate fields rather than one, because the two have genuinely
/// different jobs: an ATS parser and a JSON-LD `Person` record need the name
/// on his passport, and a visitor reading the page should meet the name he
/// actually uses. Collapsing them would mean choosing which of those to break.
///
/// Every visible surface prefers [displayName] and falls back to [name].
/// `/cv` and all structured metadata use [name] unconditionally -- see
/// `tool/generate_static.dart`.
@freezed
class Profile with _$Profile {
  /// Creates an immutable Profile record.
  const factory Profile({
    required LocalizedText name,
    required LocalizedText positioning,
    required Contact contact,
    LocalizedText? displayName,

    /// What the page opens with, before the name.
    ///
    /// The hero used to lead on the name set in the largest type on the site,
    /// which the owner said read as a wall rather than a welcome. A greeting
    /// gives the page a voice; the name still follows it, and still carries
    /// the weight.
    LocalizedText? greeting,

    /// The longer answer, for the About page.
    ///
    /// About used to print `positioning`, the same sentence the home page
    /// opens with, so a visitor who clicked through to read about the person
    /// got the strapline again. This is the page where there is room to say
    /// something a job title cannot.
    LocalizedText? biography,

    /// Where the work has been, as ISO country codes.
    ///
    /// Rendered as flags beside a line of copy. Kept here rather than derived
    /// from the career file because it includes places a client was rather
    /// than places a desk was: the Tripster team was in Russia while the
    /// employer was in Armenia, and both are true.
    @Default(<String>[]) List<String> reach,
    LocalizedText? location,
    LocalizedText? status,
    Venture? venture,
    String? cvFile,
    Portrait? portrait,
    @Default(<ProfileStat>[]) List<ProfileStat> stats,
  }) = _Profile;

  const Profile._();

  /// Decodes the documented JSON shape.
  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  /// What to show a reader: [displayName] where the owner set one, else [name].
  ///
  /// Exists so no call site has to remember the rule. A surface that wants the
  /// legal name asks for [name] deliberately, which makes the two places that
  /// do -- `/cv` and the JSON-LD -- read as decisions rather than oversights.
  LocalizedText get shownName => displayName ?? name;
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

    /// The owner's Linktree, which collects the same destinations in one page.
    Uri? linktree,
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
