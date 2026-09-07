import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/app_origin.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';

/// One shipped application, as a visual card.
///
/// The screen spec argued for a ledger over a card grid, and its reason was
/// specific: cards would put "twelve identical rounded rectangles on screen"
/// and lose the fact that these are shipped products with store links.
///
/// Both halves of that objection are answered here rather than ignored. The
/// artwork is `StationCard`, which is seeded from the application id and draws
/// the propagation map's own node vocabulary — so no two cards are alike, and
/// an application with a recorded country places its node where the country
/// is. And the store links stay as their own explicit, separately focusable
/// controls rather than being folded into the card's tap target, so what the
/// page is *for* is still the most actionable thing on it.
///
/// There is deliberately no decorative hover on the card body. The design
/// system says motion answers actions, and a card that lights up without
/// offering anything to press is motion answering nothing. The interaction
/// lives where the actions are: each store link hovers, takes focus and shows
/// a focus ring.
class WorkCard extends StatelessWidget {
  /// [origin] carries the country and coordinates when the content records one.
  const WorkCard({
    required this.app,
    required this.domainLabel,
    required this.origin,
    super.key,
  });

  /// The application this card stands for.
  final ShippedApp app;

  /// Localised domain name.
  final String domainLabel;

  /// Where the work happened, when the content records it.
  final AppOrigin? origin;

  /// Declared, never inferred. Wide enough for the name at display-m.
  static const double width = 280;

  /// The artwork's height. Above `StationCard`'s derived labelling threshold,
  /// so the card carries the application's name itself at display-m rather
  /// than repeating it underneath.
  static const double artHeight = 160;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final metric = app.metric;
    final role = app.role?.resolve(context.channel);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          StationCard(
            seedId: app.id,
            name: app.name,
            width: width,
            height: artHeight,
            domainLabel: domainLabel,
            country: origin?.country,
            latitude: origin?.latitude,
            longitude: origin?.longitude,
          ),
          if (role != null) ...[
            SizedBox(height: tokens.space12),
            Text(role, style: type.bodyS.copyWith(color: tokens.textSecondary)),
          ],
          if (metric != null) ...[
            SizedBox(height: tokens.space8),
            // The strongest single string a card can carry, so it gets the
            // instrument treatment rather than being another line of prose.
            Text(
              metric,
              style: type.telemetry.copyWith(color: tokens.instrument),
            ),
          ],
          SizedBox(height: tokens.space12),
          _StoreLinks(app: app),
        ],
      ),
    );
  }
}

/// The store destinations, or a plain line saying there are none.
class _StoreLinks extends StatelessWidget {
  const _StoreLinks({required this.app});

  final ShippedApp app;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    if (app.store.isEmpty) {
      // An absence the reader has to interpret would be worse than a line
      // saying so.
      return Text(
        l10n.workNoStoreLink,
        style: context.type.telemetryS.copyWith(color: tokens.textMuted),
      );
    }

    return Wrap(
      spacing: tokens.space16,
      runSpacing: tokens.space8,
      children: [
        for (final MapEntry(key: platform, value: url) in app.store.entries)
          _StoreLink(
            app: app,
            url: url,
            label: switch (platform) {
              AppPlatform.ios => l10n.workAppStore,
              AppPlatform.android => l10n.workGooglePlay,
            },
          ),
      ],
    );
  }
}

class _StoreLink extends StatefulWidget {
  const _StoreLink({required this.app, required this.url, required this.label});

  final ShippedApp app;
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
