import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/widgets/loading/sweep_shimmer.dart';

/// The three-stage image resolve from section 11, mirroring signal acquisition.
///
/// 1. the inline placeholder, a 20x25 image scaled up — the upscale *is* the
///    blur, so no filter is applied and no extra value is invented;
/// 2. the scan band passing over it while the full image loads;
/// 3. a 280ms cross-fade to sharp on the emphasized curve.
///
/// [width] and [height] are required with no exception: an image without
/// dimensions is a layout shift waiting to happen. A load failure falls back to
/// [fallback], which is a station card wherever an application supplies one.
class ThreeStageImage extends StatelessWidget {
  /// [placeholder] carries the inline placeholder bytes when one was extracted.
  const ThreeStageImage({
    required this.image,
    required this.width,
    required this.height,
    required this.fallback,
    this.placeholder,
    this.semanticLabel,
    super.key,
  });

  /// The full-resolution image.
  final ImageProvider<Object> image;

  /// Exact width; declared, never inferred.
  final double width;

  /// Exact height; declared, never inferred.
  final double height;

  /// Shown when the image fails to load.
  final Widget fallback;

  /// Inline placeholder bytes, absent until the extraction step exists.
  final Uint8List? placeholder;

  /// Description of the resolved image for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Image(
      image: image,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        final isResolved = frame != null;
        return Semantics(
          liveRegion: !isResolved,
          image: isResolved,
          label: isResolved ? semanticLabel : context.l10n.loadingImage,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Placeholder(bytes: placeholder, isSweeping: !isResolved),
              AnimatedOpacity(
                opacity: isResolved ? 1 : 0,
                duration: ReducedMotion.duration(context, Tokens.imageResolve),
                curve: MotionCurves.emphasized,
                child: child,
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Stage one and two: the blurred placeholder, scanned while the image loads.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.bytes, required this.isSweeping});

  final Uint8List? bytes;
  final bool isSweeping;

  @override
  Widget build(BuildContext context) {
    final source = bytes;
    final surface = source == null
        // No placeholder was extracted, so the panel surface stands in. It is
        // still the right dimensions, so nothing shifts when the image lands.
        ? ColoredBox(color: context.tokens.surface)
        : Image.memory(
            source,
            fit: BoxFit.cover,
            // Bilinear upscaling from 20x25 is what produces the blur, so no
            // filter is applied and the default sampling is left alone.
            gaplessPlayback: true,
          );
    final placeholder = ExcludeSemantics(child: surface);
    return isSweeping ? SweepShimmer(child: placeholder) : placeholder;
  }
}
