import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/app_origin.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/core/widgets/loading/three_stage_image.dart';

/// One shipped application, as a row on the ledger.
///
/// Screen spec: hairline-separated rows, not cards. Twelve identical rounded
/// rectangles would lose the fact that these are shipped products with store
/// links, which is the entire point of the page.
class LedgerRow extends StatefulWidget {
  /// [origin] is where the work happened, when the content records it.
  const LedgerRow({
    required this.app,
    required this.domainLabel,
    required this.origin,
    super.key,
  });

  /// The application.
  final ShippedApp app;

  /// Localised domain name.
  final String domainLabel;

  /// Resolved origin, or null.
  final AppOrigin? origin;

  @override
  State<LedgerRow> createState() => _LedgerRowState();
}

class _LedgerRowState extends State<LedgerRow> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final isTouch = context.platform.isTouch;
    final role = widget.app.role?.resolve(context.channel);
    final metric = widget.app.metric;

    return ListenableBuilder(
      listenable: _states,
      builder: (context, _) {
        final isHovered = _states.value.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: tokens.hairline,
                width: tokens.hairlineWidth,
              ),
            ),
          ),
          child: MouseRegion(
            onEnter: (_) => _states.update(WidgetState.hovered, true),
            onExit: (_) => _states.update(WidgetState.hovered, false),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.space16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The hover bar, and the space it occupies at rest, so the
                  // row's text never shifts sideways under the pointer.
                  AnimatedContainer(
                    duration: ReducedMotion.duration(context, Motion.quick),
                    width: tokens.heroRuleHeight,
                    height: tokens.space48,
                    color: isHovered ? tokens.beacon : Colors.transparent,
                  ),
                  SizedBox(width: tokens.space16),
                  // On touch the preview is always visible as a thumbnail;
                  // there is no hover to reveal it with.
                  if (isTouch) ...[
                    _Preview(app: widget.app, origin: widget.origin, size: 48),
                    SizedBox(width: tokens.space16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(widget.app.name, style: type.heading),
                            ),
                            Text(
                              widget.domainLabel,
                              style: type.telemetryS.copyWith(
                                color: tokens.instrumentMid,
                              ),
                            ),
                            if (widget.origin != null) ...[
                              SizedBox(width: tokens.space12),
                              Text(
                                widget.origin!.country,
                                style: type.telemetryS.copyWith(
                                  color: tokens.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (role != null)
                          Text(
                            role,
                            style: type.bodyS.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        // The strongest string on this page wherever it exists.
                        if (metric != null)
                          Text(
                            metric,
                            style: type.telemetry.copyWith(
                              color: tokens.beacon,
                            ),
                          ),
                        SizedBox(height: tokens.space8),
                        _StoreLinks(app: widget.app, l10n: l10n),
                      ],
                    ),
                  ),
                  if (!isTouch && isHovered) ...[
                    SizedBox(width: tokens.space24),
                    _Preview(app: widget.app, origin: widget.origin, size: 120),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The application's preview: its screenshot, or the procedural card.
///
/// The card is the designed treatment for an application with no screenshot,
/// built in task 1.4b — a considered absence rather than a gap. Milestone 4
/// added the other half: a `screenshot` path in the content swaps it for the
/// real thing, at identical geometry, so the ledger never shifts and the owner
/// can fill the grid in one-line edits as screenshots arrive.
class _Preview extends StatelessWidget {
  const _Preview({required this.app, required this.origin, required this.size});

  final ShippedApp app;
  final AppOrigin? origin;
  final double size;

  @override
  Widget build(BuildContext context) {
    final width = size * context.tokens.mapAspectRatio;
    final card = StationCard(
      seedId: app.id,
      name: app.name,
      width: width,
      height: size,
      country: origin?.country,
      latitude: origin?.latitude,
      longitude: origin?.longitude,
    );
    final screenshot = app.screenshot;

    return ExcludeSemantics(
      child: screenshot == null
          ? card
          : ThreeStageImage(
              image: AssetImage(screenshot),
              width: width,
              height: size,
              // A path that points at nothing falls back to the card rather
              // than a broken-image glyph, so a typo in content degrades to
              // the previous appearance instead of a visible defect.
              fallback: card,
              semanticLabel: app.name,
            ),
    );
  }
}

/// The row's store links, or a plain statement that there is no listing.
class _StoreLinks extends StatelessWidget {
  const _StoreLinks({required this.app, required this.l10n});

  final ShippedApp app;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (app.store.isEmpty) {
      // Mokaf has no public listing. Saying so plainly is better than an
      // absence the reader has to interpret.
      return Text(
        l10n.workNoStoreLink,
        style: context.type.meta.copyWith(color: tokens.textMuted),
      );
    }

    return Wrap(
      spacing: tokens.space16,
      children: [
        for (final entry in app.store.entries)
          _StoreLink(
            app: app,
            platform: entry.key,
            url: entry.value,
            label: switch (entry.key) {
              AppPlatform.ios => l10n.workAppStore,
              AppPlatform.android => l10n.workGooglePlay,
              AppPlatform.pub => l10n.workPubDev,
            },
          ),
      ],
    );
  }
}

class _StoreLink extends StatefulWidget {
  const _StoreLink({
    required this.app,
    required this.platform,
    required this.url,
    required this.label,
  });

  final ShippedApp app;
  final AppPlatform platform;
  final Uri url;
  final String label;

  @override
  State<_StoreLink> createState() => _StoreLinkState();
}

class _StoreLinkState extends State<_StoreLink> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      link: true,
      label: context.l10n.workOpenStore(widget.app.name, widget.label),
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) => FocusRing(
          isFocused: _states.value.contains(WidgetState.focused),
          child: InkWell(
            onTap: () => unawaited(
              launchUrl(widget.url, mode: LaunchMode.externalApplication),
            ),
            statesController: _states,
            borderRadius: BorderRadius.circular(tokens.controlRadius),
            hoverColor: Colors.transparent,
            mouseCursor: context.platform.isPointer
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: context.platform.minimumTarget,
              ),
              child: Center(
                widthFactor: 1,
                child: ExcludeSemantics(
                  child: Text(
                    widget.label,
                    style: context.type.bodyS.copyWith(color: tokens.beacon),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
