import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/content/content_repository.dart';

part 'providers.g.dart';

/// Where published overrides come from, or null to read only the bundle.
///
/// **Declared here and filled in by `bootstrap.dart`, deliberately.** The real
/// reader speaks HTTP, and this file is a generated library: pulling
/// `package:http` into its dependency graph makes `riverpod_generator` fail
/// while serialising the summary, because the pinned analyser is older than
/// the language version some of that graph is written in. The failure is
/// obscure and lands on an unrelated file, so it is worth naming here.
///
/// Defaulting to null is also the right behaviour rather than a workaround. A
/// test builds a bundle-only repository by doing nothing, and a build with no
/// relay never constructs a client it was not going to use.
final publishedContentProvider = Provider<RemoteReader?>((ref) => null);

/// Retains one asset cache per reader and app scope, with no global state.
@Riverpod(keepAlive: true)
class Content extends _$Content {
  @override
  ContentRepository build(AssetReader reader) =>
      ContentRepository(reader, remote: ref.watch(publishedContentProvider));
}
