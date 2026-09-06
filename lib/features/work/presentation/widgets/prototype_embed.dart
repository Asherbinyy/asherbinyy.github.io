import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/work/presentation/widgets/embed_view.dart';

/// A third-party prototype, behind a poster and an explicit click to load.
///
/// The screen spec puts City Loom's interactive prototype at the top of its
/// case study so a recruiter can use it without leaving the site, "lazy-loaded,
/// with a static poster frame and a click-to-load control so it costs nothing
/// on first paint".
///
/// The control is not only a performance measure. Loading a frame from another
/// origin the moment the page opens would make a request to a third party on
/// the viewer's behalf before they asked for it — which is the posture
/// `06-ANALYTICS-AND-PRIVACY.md` takes for everything else on this site. So
/// the poster states plainly what pressing it will do.
class PrototypeEmbed extends StatefulWidget {
  /// [url] is the prototype's address; [status] is the honest one-line status.
  const PrototypeEmbed({
    required this.url,
    required this.status,
    required this.title,
    super.key,
  });

  /// Where the prototype lives.
  final Uri url;

  /// The one honest status line the spec requires above the frame.
  final String status;

  /// Accessible name for the loaded frame.
  final String title;

  /// Declared, never inferred, so nothing shifts when the frame arrives.
  static const double height = 520;

  @override
  State<PrototypeEmbed> createState() => _PrototypeEmbedState();
}

class _PrototypeEmbedState extends State<PrototypeEmbed> {
  bool _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Above the frame, per the spec: understating an early-stage prototype
        // is safe, overstating it is not.
        Text(
          widget.status,
          style: context.type.telemetryS.copyWith(color: tokens.textMuted),
        ),
        SizedBox(height: tokens.space8),
        SizedBox(
          height: PrototypeEmbed.height,
          child: _isLoaded
              ? EmbedView(url: widget.url, title: widget.title)
              : _Poster(onLoad: () => setState(() => _isLoaded = true)),
        ),
      ],
    );
  }
}

/// The static frame shown until the viewer asks for the prototype.
class _Poster extends StatelessWidget {
  const _Poster({required this.onLoad});

  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return InstrumentPanel(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.caseStudyPrototypeWeight,
                textAlign: TextAlign.center,
                style: context.type.body.copyWith(color: tokens.textSecondary),
              ),
              SizedBox(height: tokens.space16),
              BeaconButton(
                label: l10n.caseStudyLoadPrototype,
                emphasis: ButtonEmphasis.primary,
                onPressed: onLoad,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
