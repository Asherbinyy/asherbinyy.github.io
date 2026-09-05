import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/content/content_repository.dart';

part 'providers.g.dart';

/// Retains one asset cache per reader and app scope, with no global state.
@Riverpod(keepAlive: true)
class Content extends _$Content {
  @override
  ContentRepository build(AssetReader reader) => ContentRepository(reader);
}
