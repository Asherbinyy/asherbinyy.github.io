import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/painting/cartouche_painter.dart';

/// The owner's name, enclosed as a scribe would enclose it.
///
/// `12-MOTIF-LIBRARY.md` §2 sets three rules for this and they are the whole
/// reason the widget exists rather than a bare `CustomPaint`:
///
/// 1. The Latin name is **always** present beside the glyphs, at every
///    breakpoint. The cartouche is ornament with provenance, never the only
///    way to read who this is.
/// 2. The accessible name is the Latin name. A screen reader gets `Sherbini`
///    and never a description of six signs.
/// 3. It spells one name and is not a generator.
///
/// The transliteration is recorded as unverified in `14-PROVENANCE.md` §3.14
/// until someone who reads Egyptian confirms it. Everything else on this site
/// is sourced; this has to be too, and it ships marked rather than assumed.
class NameCartouche extends StatelessWidget {
  /// [name] is the Latin name, which is what is announced and what is read.
  const NameCartouche({
    required this.name,
    required this.height,
    this.showName = true,
    super.key,
  });

  /// The owner's name in Latin script.
  final String name;

  /// The cartouche's height. Width follows from the aspect ratio.
  final double height;

  /// Whether this widget renders the Latin name itself.
  ///
  /// Set false **only** where the caller already renders the same name
  /// immediately adjacent — the hero does, at display-xl, directly beneath.
  /// Rule 1 is that the Latin name is present at every breakpoint, not that
  /// this particular widget is the thing that draws it, and drawing it twice
  /// in the hero would be worse than not drawing it here.
  ///
  /// The accessible label carries the name either way, so a screen reader is
  /// never handed a nameless ornament.
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      // One node for the pair: the glyphs and the Latin name are two renderings
      // of one thing, and announcing them separately would say it twice.
      container: true,
      label: name,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: height * CartouchePainter.aspectRatio,
              height: height,
              child: CustomPaint(
                painter: CartouchePainter(
                  colour: tokens.beacon,
                  // A step quieter than the loop, so the shape reads first and
                  // the signs second. Both are gold: the name is the person,
                  // and section 2 reserves gold for exactly that.
                  glyphColour: tokens.beaconDim,
                  strokeWidth: tokens.hairlineWidth * 2,
                ),
              ),
            ),
            if (showName) ...[
              SizedBox(height: tokens.space8),
              // Rule 1, and it is not optional. The glyphs are ornament with
              // provenance; this is how the name is actually read. It shipped
              // missing on the first pass, which is exactly the failure the
              // rule exists to prevent.
              Text(name, style: context.type.displayM),
            ],
          ],
        ),
      ),
    );
  }
}
