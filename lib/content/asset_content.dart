import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/content/content_repository.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/models/education.dart';
import 'package:nocturne/content/models/interests.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/content/providers.dart';

part 'asset_content.g.dart';

/// Bundle access, injected rather than imported.
///
/// The default fails every read, so a test or a forgotten bootstrap exercises
/// the repository's documented fallback path instead of silently reading the
/// real bundle. `main.dart` overrides it with `rootBundle.loadString`.
@Riverpod(keepAlive: true)
AssetReader assetReader(AssetReaderRef ref) => _unavailable;

Future<String> _unavailable(String path) =>
    Future<String>.error(StateError('No asset reader is installed.'));

/// The repository, wired to whichever reader is installed.
@Riverpod(keepAlive: true)
ContentRepository contentRepository(ContentRepositoryRef ref) =>
    ref.watch(contentProvider(ref.watch(assetReaderProvider)));

/// Identity and contact, falling back to the bundled minimum.
@Riverpod(keepAlive: true)
Future<ContentResult<Profile>> profile(ProfileRef ref) =>
    ref.watch(contentRepositoryProvider).profile();

/// The shipped application ledger.
@Riverpod(keepAlive: true)
Future<ContentResult<Apps>> apps(AppsRef ref) =>
    ref.watch(contentRepositoryProvider).apps();

/// Qualifications, as the owner recorded them.
@Riverpod(keepAlive: true)
Future<ContentResult<Education>> education(EducationRef ref) =>
    ref.watch(contentRepositoryProvider).education();

/// Career stations, in the order the content declares them.
@Riverpod(keepAlive: true)
Future<ContentResult<Career>> career(CareerRef ref) =>
    ref.watch(contentRepositoryProvider).career();

/// What the owner does when he is not working.
@Riverpod(keepAlive: true)
Future<ContentResult<Interests>> interests(InterestsRef ref) =>
    ref.watch(contentRepositoryProvider).interests();
