import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';

/// An application's own screens, in a row you can push along.
///
/// Phone screenshots are tall and narrow, so a grid of them wastes most of the
/// page and shrinks each one below the size where anything in it can be read.
/// A horizontal strip at close to phone proportions keeps them legible, and
/// there are only ever a handful, so there is nothing to paginate.
///
/// Tapping one opens it full size. That is not decoration: at strip size a
/// dashboard is an impression of a dashboard, and somebody looking at a
/// portfolio wants to see whether the work is any good.
class AppShots extends StatelessWidget {
  /// Shows [paths] — asset paths, in reading order.
  const AppShots({required this.paths, required this.appName, super.key});

  /// Asset paths, in the order they should be read.
  final List<String> paths;

  /// Named in each image's description, so a screen reader says whose it is.
  final String appName;

  /// One frame's height in the strip. Tall, because phones are.
  static const double stripHeight = 420;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;

    return SizedBox(
      height: stripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: paths.length,
        separatorBuilder: (context, _) => SizedBox(width: tokens.space16),
        itemBuilder: (context, index) => _Shot(
          path: paths[index],
          label: context.l10n.workShotOf(appName, index + 1, paths.length),
        ),
      ),
    );
  }
}

class _Shot extends StatelessWidget {
  const _Shot({required this.path, required this.label});

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        child: ExcludeSemantics(
          child: InstrumentPanel(
            fill: tokens.surface,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              child: Image.asset(
                path,
                height: AppShots.stripHeight,
                fit: BoxFit.contain,
                // A missing file is a content mistake, not a crash. The strip
                // simply loses a frame.
                errorBuilder: (context, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierColor: context.tokens.void_.withValues(alpha: 0.88),
        builder: (context) => _Full(path: path, label: label),
      ),
    );
  }
}

/// One screenshot at whatever size the window allows.
class _Full extends StatelessWidget {
  const _Full({required this.path, required this.label});

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(tokens.space24),
      child: Semantics(
        label: label,
        child: GestureDetector(
          // Anywhere closes it. A viewer who has opened a picture wants out of
          // it more often than they want a button.
          onTap: () => Navigator.of(context).maybePop(),
          child: AnimatedOpacity(
            opacity: 1,
            duration: ReducedMotion.duration(context, Motion.quick),
            child: Image.asset(path, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
