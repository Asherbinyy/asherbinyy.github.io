// @dart=3.9
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nocturne/content/models/localized_text.dart';
part 'gallery.freezed.dart';
part 'gallery.g.dart';

/// Image or external video, as the owner explicitly selected.
enum GalleryKind {
  /// An image from the bundle or media store.
  image,

  /// An HTTPS video destination, opened only by a deliberate press.
  video,
}

/// Shared by project and interest galleries.
@freezed
class GalleryEntry with _$GalleryEntry {
  /// Creates an entry without supplying missing media or captions.
  const factory GalleryEntry({
    required String id,
    required GalleryKind kind,
    required LocalizedText alt,
    String? image,
    Uri? url,
    LocalizedText? caption,
  }) = _GalleryEntry;

  /// Decodes the admin contract.
  factory GalleryEntry.fromJson(Map<String, dynamic> json) =>
      _$GalleryEntryFromJson(json);
}
