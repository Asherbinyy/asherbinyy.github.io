import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/features/colophon/domain/build_facts.dart';

import 'dart:convert';

/// The generated build measurements, or null when the file is absent.
///
/// Read through the same injected asset reader the content layer uses, so a
/// test supplies its own figures without touching the bundle.
final buildFactsProvider = FutureProvider<BuildFacts?>((ref) async {
  final read = ref.watch(assetReaderProvider);
  try {
    final Object? json = jsonDecode(await read('assets/build_facts.json'));
    if (json is! Map<String, dynamic>) return null;
    return parseBuildFacts(json);
  } on Object {
    // A page about how carefully this was built should not itself crash
    // because a generated file was missing.
    return null;
  }
});
