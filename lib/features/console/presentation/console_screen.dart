import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/loading/carrier_loader.dart';
import 'package:nocturne/features/console/data/console_providers.dart';

import 'package:nocturne/features/console/presentation/console_dashboard.dart'
    deferred as dashboard;

/// `/console` — the analytics dashboard, behind the owner's token.
///
/// **Code-split, per roadmap 2.5.** The dashboard is a `deferred as` import, so
/// its widgets, its chart and its summary logic are downloaded only when a
/// token has actually been accepted. A public visitor who wanders onto this
/// path pays for the gate and nothing else — which matters on a site whose
/// whole argument includes its own payload.
///
/// Not linked from anywhere in the public site, per the screen spec. It is
/// reachable only by typing the path.
class ConsoleScreen extends ConsumerStatefulWidget {
  /// Shows the gate, then the deferred dashboard.
  const ConsoleScreen({super.key});

  @override
  ConsumerState<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends ConsumerState<ConsoleScreen> {
  Future<void>? _loading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final token = ref.watch(consoleTokenProvider);

    if (token != null && token.isNotEmpty) {
      _loading ??= dashboard.loadLibrary();
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: tokens.space48,
        bottom: tokens.space64,
      ),
      child: token == null || token.isEmpty
          ? const _Gate()
          : FutureBuilder<void>(
              future: _loading,
              builder: (context, snapshot) =>
                  snapshot.connectionState == ConnectionState.done
                  ? dashboard.ConsoleDashboard()
                  : const CarrierLoader(),
            ),
    );
  }
}

/// The token prompt. No account, no session, no cookie — one bearer token.
class _Gate extends ConsumerStatefulWidget {
  const _Gate();

  @override
  ConsumerState<_Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<_Gate> {
  final TextEditingController _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _field.text.trim();
    if (value.isEmpty) return;
    ref.read(consoleTokenProvider.notifier).state = value;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.consoleTokenPrompt, style: context.type.displayM),
        SizedBox(height: tokens.space24),
        SizedBox(
          width: context.type.measureFor(context.type.body),
          child: TextField(
            controller: _field,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: l10n.consoleTokenLabel),
          ),
        ),
        SizedBox(height: tokens.space16),
        BeaconButton(
          label: l10n.consoleSignIn,
          emphasis: ButtonEmphasis.primary,
          onPressed: _submit,
        ),
      ],
    );
  }
}
