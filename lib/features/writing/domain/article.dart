/// One published article, as the feed describes it.
///
/// A record rather than a class for the same reason `AnalyticsBeacon` is one:
/// it is a value with no behaviour, and records give equality and hashing
/// without a generator or a hand-written `operator ==`.
///
/// There is deliberately no body or excerpt field. `00-PROJECT-BRIEF.md` §7
/// keeps writing on Medium rather than building a blog engine, so this site
/// lists what exists and links out. Rendering feed HTML would make it a reader.
typedef Article = ({
  String title,
  Uri url,
  DateTime? published,
  List<String> tags,

  /// The article's cover image on Medium's CDN, where the feed carries one.
  ///
  /// This is the upstream URL, not something the browser ever requests
  /// directly — see `coverProxy` in `writing_providers.dart`. Keeping the
  /// original here rather than a pre-built proxy URL means the relay's shape
  /// is a presentation concern and the feed stays the feed.
  Uri? cover,
});
