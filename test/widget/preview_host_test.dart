import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nocturne/core/preview/preview_host.dart';
import 'package:nocturne/core/preview/preview_transport.dart';

void main() {
  testWidgets(
    'the real Flutter preview paints drafts and switches the content language',
    (tester) async {
      final transport = _Transport();
      final profile = jsonDecode(
        await rootBundle.loadString('assets/content/profile.json'),
      ) as Map<String, dynamic>;
      await tester.pumpWidget(
        ProviderScope(
          overrides: previewOverrides(),
          child: PreviewHost(transport: transport),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        transport.sent.any((message) => message['type'] == 'ready'),
        isTrue,
      );
      profile['greeting'] = {
        'en': 'Private preview draft',
        'ar': (profile['name'] as Map)['ar'],
      };
      transport.receive!({
        'type': 'draft',
        'payload': {
          'requestId': 1,
          'schemaVersion': 1,
          'locale': 'en',
          'file': 'profile.json',
          'document': profile,
          'route': '/',
        },
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Private preview draft'), findsOneWidget);
      expect(
        transport.sent.any(
          (message) =>
              message['type'] == 'rendered' &&
              (message['payload'] as Map)['requestId'] == 1,
        ),
        isTrue,
      );
      transport.receive!({
        'type': 'draft',
        'payload': {
          'requestId': 2,
          'schemaVersion': 1,
          'locale': 'ar',
          'file': 'profile.json',
          'document': profile,
          'route': '/',
        },
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.text((profile['name'] as Map)['ar'] as String),
        findsOneWidget,
      );
      expect(find.text('Private preview draft'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(transport.disposed, isTrue);
    },
  );
}

class _Transport implements PreviewTransport {
  void Function(Map<String, dynamic>)? receive;
  final sent = <Map<String, dynamic>>[];
  bool disposed = false;
  @override
  void listen(void Function(Map<String, dynamic>) receive) =>
      this.receive = receive;
  @override
  void send(String type, Map<String, dynamic> payload) =>
      sent.add({'type': type, 'payload': payload});
  @override
  void dispose() => disposed = true;
}
