import 'package:flutter/foundation.dart' show ValueListenable;

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/study.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/core/widgets/loading/three_stage_image.dart';

/// The pinned phone frame that scrubs through a study's screens.
///
/// The screen spec pins this to the right column and advances it as the left
/// column scrolls, so the reader sees the app change while reading about it.
///
/// It rebuilds on a change of *index*, not on every scroll frame. Scroll
/// progress updates continuously, so listening to it directly would rebuild
/// the image — decode, layout, the three-stage cross-fade — sixty times a
/// second to show the same picture. `_ScrubIndex` sits in between and only
/// notifies when the screen actually changes.
class DeviceFrame extends StatefulWidget {
  /// [progress] is the page's scroll progress, 0 to 1.
  const DeviceFrame({
    required this.screens,
    required this.progress,
    required this.locale,
    required this.seedId,
    required this.title,
    super.key,
  });

  /// Declared, never inferred: a 9:19.5 phone at a legible reading size.
  static const double width = 300;

  /// Height at 9:19.5, rounded to a whole pixel.
  static const double height = 650;

  /// The study's screenshots, in the order the content declares them.
  final List<StudyScreen> screens;

  /// Page scroll progress, or null when there is no scrolling chrome.
  final ValueListenable<double>? progress;

  /// Active locale, for the caption.
  final AppLocale locale;

  /// The study id, seeding the deterministic fallback card.
  final String seedId;

  /// The study title, shown on the fallback card.
  final String title;

  /// Maps scroll progress onto a screen index.
  ///
  /// The last screen holds through the end of the page rather than being
  /// reachable only at exactly 1.0, which no scroll ever lands on.
  static int indexFor(double progress, int count) {
    if (count <= 1) return 0;
    final index = (progress.clamp(0.0, 1.0) * count).floor();
    return index >= count ? count - 1 : index;
  }

  @override
  State<DeviceFrame> createState() => _DeviceFrameState();
}

class _DeviceFrameState extends State<DeviceFrame> {
  _ScrubIndex? _index;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(DeviceFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress ||
        oldWidget.screens.length != widget.screens.length) {
      _index?.dispose();
      _attach();
    }
  }

  void _attach() {
    final progress = widget.progress;
    _index = progress == null
        ? null
        : _ScrubIndex(progress: progress, count: widget.screens.length);
  }

  @override
  void dispose() {
    _index?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.screens.isEmpty) return const _EmptyFrame();

    final index = _index;
    if (index == null) {
      return _Frame(
        screen: widget.screens.first,
        locale: widget.locale,
        seedId: widget.seedId,
        title: widget.title,
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: index,
      builder: (context, value, _) => _Frame(
        screen: widget.screens[value],
        locale: widget.locale,
        seedId: widget.seedId,
        title: widget.title,
      ),
    );
  }
}

/// Derives a screen index from scroll progress, notifying only on a change.
class _ScrubIndex extends ValueNotifier<int> {
  _ScrubIndex({required this.progress, required this.count})
    : super(DeviceFrame.indexFor(progress.value, count)) {
    progress.addListener(_update);
  }

  final ValueListenable<double> progress;
  final int count;

  void _update() {
    final next = DeviceFrame.indexFor(progress.value, count);
    if (next != value) value = next;
  }

  @override
  void dispose() {
    progress.removeListener(_update);
    super.dispose();
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.screen,
    required this.locale,
    required this.seedId,
    required this.title,
  });

  final StudyScreen screen;
  final AppLocale locale;
  final String seedId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InstrumentPanel(
          child: ThreeStageImage(
            image: AssetImage(screen.src),
            width: DeviceFrame.width,
            height: DeviceFrame.height,
            // A missing screenshot resolves to the procedural station card
            // rather than a broken-image glyph, which is the same fallback the
            // ledger uses.
            fallback: StationCard(
              seedId: seedId,
              name: title,
              width: DeviceFrame.width,
              height: DeviceFrame.height,
            ),
          ),
        ),
        SizedBox(height: tokens.space8),
        SizedBox(
          width: DeviceFrame.width,
          child: Text(
            screen.caption.resolve(locale),
            style: context.type.telemetryS.copyWith(color: tokens.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Reserves the frame's geometry when a study declares no screens.
class _EmptyFrame extends StatelessWidget {
  const _EmptyFrame();

  @override
  Widget build(BuildContext context) => InstrumentPanel(
    child: SizedBox(
      width: DeviceFrame.width,
      height: DeviceFrame.height,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(context.tokens.space16),
          child: Text(
            context.l10n.caseStudyScreensPending,
            textAlign: TextAlign.center,
            style: context.type.telemetryS.copyWith(
              color: context.tokens.textMuted,
            ),
          ),
        ),
      ),
    ),
  );
}
