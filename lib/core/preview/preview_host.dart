import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/bootstrap.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/app/router.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_parser.dart';
import 'package:nocturne/content/providers.dart';
import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/net/relay.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/core/preview/preview_transport.dart';

/// Drafts stay inside this ProviderScope; no browser storage or publishing.
final previewDocumentsProvider = StateProvider<Map<String, String>>(
  (ref) => {},
);

/// Production assets, with checked draft documents substituted in memory.
List<Override> previewOverrides() => [
  preferenceStoreProvider.overrideWithValue(InMemoryPreferenceStore()),
  defaultThemeProvider.overrideWith(publishedDefaultTheme),
  analyticsEndpointProvider.overrideWithValue(null),
  publishedContentProvider.overrideWithValue(null),
  // Preview media uses the same local/deployed relay as the owner panel.
  relayEndpointProvider.overrideWithValue(
    Uri.tryParse(const String.fromEnvironment('ADMIN_PREVIEW_ORIGIN')),
  ),
  assetReaderProvider.overrideWith((ref) {
    final drafts = ref.watch(previewDocumentsProvider);
    return (path) async => drafts[path] ?? await rootBundle.loadString(path);
  }),
];

/// Validate the entire batch before applying any part of it.
Map<String, String> checkedPreviewDocuments(Map<String, dynamic> payload) {
  if (payload['schemaVersion'] != 1 ||
      !['en', 'ar'].contains(payload['locale']) ||
      payload['requestId'] is! int) {
    throw const FormatException('Unsupported preview message');
  }
  final documents = <String, dynamic>{
    if (payload['documents'] is Map)
      ...Map<String, dynamic>.from(payload['documents'] as Map),
    payload['file'] as String: payload['document'],
  };
  return documents.map((file, document) {
    final json = jsonDecode(jsonEncode(document)) as Map<String, dynamic>;
    switch (file) {
      case 'profile.json':
        ContentParser.profile(json);
      case 'career.json':
        ContentParser.career(json);
      case 'apps.json':
        ContentParser.apps(json);
      case 'education.json':
        ContentParser.education(json);
      case 'interests.json':
        ContentParser.interests(json);
      default:
        throw const FormatException('Unsupported preview document');
    }
    return MapEntry('assets/content/$file', jsonEncode(json));
  });
}

/// The real app, with the normal routes and widgets receiving private drafts.
class PreviewHost extends ConsumerStatefulWidget {
  /// A transport with an exact origin/source/session boundary.
  const PreviewHost({required this.transport, super.key});

  /// The exact-origin browser connection.
  final PreviewTransport transport;

  @override
  ConsumerState<PreviewHost> createState() => _PreviewHostState();
}

class _PreviewHostState extends ConsumerState<PreviewHost> {
  late final GoRouter _router = AppRouter.create(preview: true);
  Locale _locale = const Locale('en');
  int _request = 0;
  static const _routes = {
    '/',
    '/journey',
    '/work',
    '/writing',
    '/services',
    '/about',
    '/courtyard',
  };

  @override
  void initState() {
    super.initState();
    widget.transport.listen(_receive);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.transport.send('ready', {
          'schemaVersions': [1],
          'components': <String>[],
        });
      }
    });
  }

  void _navigate(Object? route) {
    if (route is String &&
        _routes.contains(route) &&
        _router.routeInformationProvider.value.uri.path != route) {
      _router.go(route);
    }
  }

  Future<void> _receive(Map<String, dynamic> message) async {
    final payload = message['payload'];
    if (payload is! Map) return;
    final data = Map<String, dynamic>.from(payload);
    if (message['type'] == 'select') {
      _navigate(data['route']);
      return;
    }
    if (message['type'] != 'draft') return;
    final request = data['requestId'];
    if (request is! int || request <= _request) return;
    _request = request;
    try {
      final checked = checkedPreviewDocuments(data);
      ref.read(previewDocumentsProvider.notifier).state = {
        ...ref.read(previewDocumentsProvider),
        ...checked,
      };
      ref.read(localeControllerProvider.notifier).locale =
          data['locale'] == 'ar' ? AppLocale.arabic : AppLocale.english;
      setState(() => _locale = Locale(data['locale'] as String));
      _navigate(data['route']);
      // Resolve the content before acknowledging the resulting Flutter frame.
      await Future.wait([
        ref.read(profileProvider.future),
        ref.read(careerProvider.future),
        ref.read(appsProvider.future),
        ref.read(educationProvider.future),
        ref.read(interestsProvider.future),
      ]);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted && request == _request) {
        widget.transport.send('rendered', {
          'requestId': request,
          'errors': <String>[],
        });
      }
    } on Object {
      if (mounted && request == _request) {
        widget.transport.send('rendered', {
          'requestId': request,
          'errors': [
            {'message': 'The app rejected this draft.'},
          ],
        });
      }
    }
  }

  @override
  void dispose() {
    widget.transport.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NocturneApp(router: _router, locale: _locale);
}
