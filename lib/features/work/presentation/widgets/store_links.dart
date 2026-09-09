import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:url_launcher/url_launcher.dart';

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
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _StoreMarkPainter(platform: platform, colour: colour),
    ),
  );
}

class _StoreMarkPainter extends CustomPainter {
  const _StoreMarkPainter({required this.platform, required this.colour});

  final AppPlatform platform;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = colour;
    final w = size.width;
    final h = size.height;

    switch (platform) {
      case AppPlatform.ios:
        // A rounded body with a bite out of the right and a leaf on top.
        final body = Path()
          ..addOval(Rect.fromLTWH(0, h * 0.24, w * 0.82, h * 0.72));
        final bite = Path()
          ..addOval(Rect.fromLTWH(w * 0.52, h * 0.30, w * 0.6, h * 0.6));
        canvas
          ..drawPath(Path.combine(PathOperation.difference, body, bite), paint)
          ..drawPath(
            Path()
              ..moveTo(w * 0.40, h * 0.26)
              ..quadraticBezierTo(w * 0.46, h * 0.02, w * 0.68, h * 0.04)
              ..quadraticBezierTo(w * 0.60, h * 0.26, w * 0.40, h * 0.26)
              ..close(),
            paint,
          );
      case AppPlatform.android:
        // The play triangle.
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.18, 0)
            ..lineTo(w * 0.92, h * 0.5)
            ..lineTo(w * 0.18, h)
            ..close(),
          paint,
        );
      case AppPlatform.pub:
        // A package: a box with a lid seam, for a published library.
        canvas
          ..drawRect(
            Rect.fromLTWH(w * 0.08, h * 0.28, w * 0.84, h * 0.64),
            paint..style = PaintingStyle.fill,
          )
          ..drawLine(
            Offset(w * 0.5, h * 0.28),
            Offset(w * 0.5, h * 0.92),
            Paint()
              ..color = const Color(0x00000000)
              ..blendMode = BlendMode.clear
              ..strokeWidth = w * 0.10,
          );
    }
  }

  @override
  bool shouldRepaint(_StoreMarkPainter oldDelegate) =>
      oldDelegate.platform != platform || oldDelegate.colour != colour;
}
