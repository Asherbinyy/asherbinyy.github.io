import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/message_controller.dart';
import 'package:nocturne/core/platform/message_state.dart';

void main() {
  late ProviderContainer container;
  late MessageController controller;

  setUp(() {
    container = ProviderContainer()
      ..listen(messageControllerProvider(Tokens.messageLifetime), (_, _) {});
    controller = container.read(
      messageControllerProvider(Tokens.messageLifetime).notifier,
    );
  });
  tearDown(() => container.dispose());

  testWidgets('message expires after the documented lifetime', (tester) async {
    controller.show(text: 'Fixture message', closeLabel: 'Close fixture');

    await tester.pump(Tokens.messageLifetime - Tokens.instant);
    expect(
      container.read(messageControllerProvider(Tokens.messageLifetime)),
      isA<VisibleMessage>(),
    );
    await tester.pump(Tokens.instant);
    expect(
      container.read(messageControllerProvider(Tokens.messageLifetime)),
      isA<NoMessage>(),
    );
  });

  testWidgets('hover persists and leaving restarts the display interval', (
    tester,
  ) async {
    controller
      ..show(text: 'Fixture message', closeLabel: 'Close fixture')
      ..setHovered(value: true);

    await tester.pump(Tokens.messageLifetime * 2);
    expect(
      container.read(messageControllerProvider(Tokens.messageLifetime)),
      isA<VisibleMessage>(),
    );
    controller.setHovered(value: false);
    await tester.pump(Tokens.messageLifetime);
    expect(
      container.read(messageControllerProvider(Tokens.messageLifetime)),
      isA<NoMessage>(),
    );
  });

  testWidgets('keyboard focus persists after the pointer leaves', (
    tester,
  ) async {
    controller
      ..show(text: 'Fixture message', closeLabel: 'Close fixture')
      ..setHovered(value: true)
      ..setFocused(value: true)
      ..setHovered(value: false);

    await tester.pump(Tokens.messageLifetime * 2);
    expect(
      container.read(messageControllerProvider(Tokens.messageLifetime)),
      isA<VisibleMessage>(),
    );
    controller.setFocused(value: false);
    await tester.pump(Tokens.messageLifetime);
    expect(
      container.read(messageControllerProvider(Tokens.messageLifetime)),
      isA<NoMessage>(),
    );
  });

  testWidgets('replacement cancels the previous message timeout', (
    tester,
  ) async {
    controller.show(text: 'First fixture', closeLabel: 'Close fixture');
    await tester.pump(Tokens.messageLifetime - Tokens.instant);
    controller.show(text: 'Second fixture', closeLabel: 'Close fixture');

    await tester.pump(Tokens.instant);
    final state = container.read(
      messageControllerProvider(Tokens.messageLifetime),
    );
    expect(
      state,
      isA<VisibleMessage>().having((m) => m.text, 'text', 'Second fixture'),
    );
    await tester.pump(Tokens.messageLifetime);
    expect(
      container.read(messageControllerProvider(Tokens.messageLifetime)),
      isA<NoMessage>(),
    );
  });

  testWidgets('explicit dismissal cancels the timer', (tester) async {
    controller
      ..show(text: 'Fixture message', closeLabel: 'Close fixture')
      ..dismiss();

    await tester.pump(Tokens.messageLifetime);
    expect(
      container.read(messageControllerProvider(Tokens.messageLifetime)),
      isA<NoMessage>(),
    );
  });
}
