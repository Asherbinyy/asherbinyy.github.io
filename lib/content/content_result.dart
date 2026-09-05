import 'package:nocturne/content/models/profile.dart';

/// Explicit result of loading one section; fallback is never mistaken for it.
sealed class ContentResult<T> {
  const ContentResult();
}

/// Validated primary section content.
final class ContentReady<T> extends ContentResult<T> {
  /// Wraps a successfully validated section.
  const ContentReady(this.data);

  /// Typed content, ready for presentation.
  final T data;
}

/// The primary section failed, but the bundled identity/contact remain usable.
final class ContentFallback<T> extends ContentResult<T> {
  /// Provides minimum identity when the requested section fails.
  const ContentFallback(this.profile);

  /// The bundled minimum, not fabricated section content.
  final Profile profile;
}

/// Both primary content and the minimum fallback are unavailable or malformed.
final class ContentUnavailable<T> extends ContentResult<T> {
  /// Represents failure of both primary data and the fallback.
  const ContentUnavailable();
}
