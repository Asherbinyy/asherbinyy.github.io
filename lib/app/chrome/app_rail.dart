import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/features/trace/domain/trace_controller.dart';
import 'package:nocturne/features/trace/domain/trace_state.dart';

/// The 56px instrument frame down the leading edge.
///
/// Screen spec: a vertical scroll-position tick scale, the current section name
/// set vertically, and the trace state indicator. It is what makes the page
/// feel like a device rather than a document, which is why it is persistent
/// chrome rather than a per-screen decoration.
class AppRail extends ConsumerWidget {
  /// [progress] is scroll position through the page, 0..1.
  const AppRail({required this.sectionName, required this.progress, super.key});

  /// The current section, set vertically.
  final String sectionName;

  /// Scroll progress, 0..1.
  final double progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final trace = ref.watch(traceControllerProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: BorderDirectional(
          end: BorderSide(color: tokens.hairline, width: tokens.hairlineWidth),
        ),
      ),
      child: SizedBox(
        width: tokens.railWidth,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.space16),
                child: _TickScale(progress: progress),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.space16),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  sectionName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.telemetryS.copyWith(
                    color: tokens.instrumentMid,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: tokens.space16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  trace.label(context.l10n),
                  style: context.type.telemetryS.copyWith(
                    color: trace.isHighlighted
                        ? tokens.beacon
                        : tokens.instrumentDim,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The trace state's viewer-facing name.
extension TraceStateLabel on TraceState {
  /// Reads from ARB so the rail is legible in both channels.
  String label(AppLocalizations l10n) => switch (this) {
    TraceState.standby => l10n.traceStandby,
    TraceState.scanning => l10n.traceScanning,
    TraceState.lock => l10n.traceLock,
  };
}

/// The vertical tick scale showing scroll position.
class _TickScale extends StatelessWidget {
  const _TickScale({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          alignment: AlignmentDirectional.topCenter,
          children: [
            SizedBox(
              width: tokens.hairlineWidth,
              height: constraints.maxHeight,
              child: ColoredBox(color: tokens.hairline),
            ),
            Positioned(
              top: constraints.maxHeight * progress.clamp(0, 1),
              child: SizedBox(
                width: tokens.space16,
                height: tokens.hairlineWidth * 2,
                child: ColoredBox(color: tokens.beacon),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
