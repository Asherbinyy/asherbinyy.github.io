import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:simple_icons/simple_icons.dart';

import 'package:nocturne/core/analytics/tracked_link.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// Where an application can be downloaded.
///
/// Lifted out of the work card so the ledger and `/work/<id>` show the same
/// thing. It was private to the card, which is why the detail page had no way
/// to offer a download at all.
///
/// Two changes the owner asked for are here. Each store leads with its own
/// mark rather than its name, because a badge is recognised faster than a
/// word and survives translation. And an application with no public listing
/// now renders nothing: the line saying "No public store listing" was printed
/// on eight of fourteen cards, which made an absence into the loudest thing on
/// the page.
class StoreLinks extends StatelessWidget {
  /// Renders every listing [app] declares.
  const StoreLinks({required this.app, super.key});

  /// The application whose listings are shown.
  final ShippedApp app;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    if (app.store.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: tokens.space12,
      runSpacing: tokens.space8,
      children: [
        for (final MapEntry(key: platform, value: url) in app.store.entries)
          _StoreLink(
            app: app,
            url: url,
            platform: platform,
            label: switch (platform) {
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
    required this.url,
    required this.platform,
    required this.label,
  });

  final ShippedApp app;
  final Uri url;
  final AppPlatform platform;
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
              launchTrackedUrl(
                context,
                widget.url,
                target: 'app:${widget.app.id}:${widget.platform.name}',
              ),
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
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tokens.controlRadius),
                    border: Border.all(
                      color: tokens.hairlineStrong,
                      width: tokens.hairlineWidth,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.space12,
                      vertical: tokens.space8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StoreMark(
                          platform: widget.platform,
                          colour: tokens.beacon,
                          size: context.type.bodyS.fontSize ?? 14,
                        ),
                        SizedBox(width: tokens.space8),
                        Text(
                          widget.label,
                          style: context.type.bodyS.copyWith(
                            color: tokens.beacon,
                          ),
                        ),
                      ],
                    ),
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

/// Each store's mark, drawn rather than bundled.
///
/// Apple's and Google's badges are trademarks with brand guidelines attached,
/// and shipping their artwork would put someone else's licence into a
/// repository whose whole provenance file exists to avoid that. These are
/// plain geometric stand-ins in the site's own palette: an apple, a play
/// triangle, a package. They say which store without pretending to be the
/// badge.
/// Which mark a platform gets, shared by both places that print one.
///
/// pub.dev has no mark of its own in the set, so a package published there
/// carries the Dart mark: it is the same organisation's, and it says the true
/// thing about what the listing is.
IconData storeIconFor(AppPlatform platform) => switch (platform) {
  AppPlatform.ios => SimpleIcons.appstore,
  AppPlatform.android => SimpleIcons.googleplay,
  AppPlatform.pub => SimpleIcons.dart,
};

/// The store's own mark.
///
/// These used to be drawn by hand -- an apple with a bite taken out of it, a
/// play triangle, a box for a package. Redrawing a company's trademark from
/// memory is both worse-looking and the wrong thing to do, so they come from
/// the Simple Icons set now, which is assembled from the vendors' own brand
/// pages.
class _StoreMark extends StatelessWidget {
  const _StoreMark({
    required this.platform,
    required this.colour,
    required this.size,
  });

  final AppPlatform platform;
  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(storeIconFor(platform), size: size, color: colour);
}
