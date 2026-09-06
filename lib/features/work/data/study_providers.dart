import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/study.dart';

/// One case study by slug.
///
/// The repository rejects a slug that could escape the studies directory, so a
/// crafted path in the URL bar throws rather than reading an arbitrary asset.
/// That throw surfaces here as an `AsyncError`, which the screen renders as
/// "not written yet" — the same thing a genuinely absent study shows, because
/// the two are indistinguishable to a viewer and neither is worth a stack
/// trace on screen.
final studyProvider = FutureProvider.family<ContentResult<Study>, String>(
  (ref, slug) => ref.watch(contentRepositoryProvider).study(slug),
);
