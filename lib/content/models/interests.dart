// @dart=3.9
// Freezed 2 emits final formal parameters; retain its supported syntax here.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:nocturne/content/models/localized_text.dart';

part 'interests.freezed.dart';
part 'interests.g.dart';

/// What the owner does when he is not working.
///
/// A separate document from `profile.json` because it is the one part of the
/// content a recruiter may never read and the owner cares most about. Keeping
/// it apart means it can grow, or be pulled entirely, without touching the
/// identity every other surface depends on.
@freezed
class Interests with _$Interests {
  /// Creates an immutable Interests record.
  const factory Interests({required List<Interest> interests}) = _Interests;

  /// Decodes the documented JSON shape.
  factory Interests.fromJson(Map<String, dynamic> json) =>
      _$InterestsFromJson(json);
}

/// One thing the owner does, and optionally the specific he named.
///
/// [note] exists because "television" says nothing and "Better Call Saul" says
/// a great deal. It is absent wherever the owner did not name a specific, and
/// nothing infers one: `AGENTS.md` §3 covers a favourite show as surely as it
/// covers a download count.
@freezed
class Interest with _$Interest {
  /// Creates an immutable Interest record.
  const factory Interest({
    required String id,
    required LocalizedText label,
    LocalizedText? note,
  }) = _Interest;

  /// Decodes the documented JSON shape.
  factory Interest.fromJson(Map<String, dynamic> json) =>
      _$InterestFromJson(json);
}
