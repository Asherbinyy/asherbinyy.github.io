import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/core/widgets/loading/three_stage_image.dart';

/// The 4:5 portrait slot from the screen spec.
///
/// The owner supplied the photograph on 2026-09-07, closing an item open since
/// milestone 1. It resolves through [ThreeStageImage] like every other image
/// on the site, so a failed load degrades to the empty frame rather than to a
/// broken-image glyph, and the geometry is identical either way — nothing
/// moves whether the file resolves or not.
///
/// `profile.portrait` is still read rather than hard-coded. The content layer
/// owns what the site says about the owner, and a path baked into a widget is
/// one an owner cannot change by editing JSON.
class PortraitFrame extends ConsumerWidget {
  /// Reads `profile.portrait`.
  const PortraitFrame({super.key});

  /// Declared, never inferred — the 4:5 ratio the spec asks for.
  static const double width = 280;

  /// Height at 4:5.
  static const double height = 350;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portrait = switch (ref.watch(profileProvider).valueOrNull) {
      ContentReady<Profile>(:final data) => data.portrait,
      _ => null,
    };

    // A portrait explicitly marked as a placeholder is not the owner, so it
    // is not shown as him. The empty frame is the honest render.
    if (portrait == null || portrait.isPlaceholder) return const _EmptyFrame();

    return InstrumentPanel(
      child: ThreeStageImage(
        image: AssetImage(portrait.src),
        width: width,
        height: height,
        fallback: const _EmptyFrame(),
        semanticLabel: context.l10n.aboutPortraitLabel,
      ),
    );
  }
}

/// The reserved slot, when no portrait resolves.
///
/// Says plainly that the frame is empty rather than shipping a stock face, an
/// avatar initial, or a silhouette a viewer might mistake for the person.
class _EmptyFrame extends StatelessWidget {
  const _EmptyFrame();

  @override
  Widget build(BuildContext context) => InstrumentPanel(
    child: SizedBox(
      width: PortraitFrame.width,
      height: PortraitFrame.height,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(context.tokens.space16),
          child: Text(
            context.l10n.aboutPortraitPending,
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
