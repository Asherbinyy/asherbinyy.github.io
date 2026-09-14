import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

import 'package:nocturne/app/theme/tokens.dart';

/// The 48px footer: a closing rule, and nothing else.
///
/// It carried a coordinate readout and the owner's city until milestone 4.
/// Task 4.9 removed the coordinate, and the owner then asked for the city to
/// go too — a footer that introduces someone by their location reads as a form
/// field rather than as a person, and his location is already on `/about`,
/// `/cv` and `/brief` where a recruiter looks for it.
///
/// The row keeps its height and its top hairline. That is deliberate: the rule
/// terminates the content column so a short page does not simply stop, and the
/// reserved height is what stops the footer moving when a page grows. An empty
/// bar is the honest result of having nothing to say here, and inventing a
/// tagline to fill it would be exactly the kind of copy the owner objected to.
class AppFooter extends StatelessWidget {
  /// Creates the footer.
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.void_,
        border: Border(
          top: BorderSide(color: tokens.hairline, width: tokens.hairlineWidth),
        ),
      ),
      child: SizedBox(
        height: tokens.footerHeight,
        width: double.infinity,
        // The colophon. One quiet line, because the guardian in the intro is
        // a Creative Commons work whose licence requires attribution -- it is
        // a condition of using the model, not a flourish that can be dropped.
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: context.platform.gutter),
            child: const _Colophon(),
          ),
        ),
      ),
    );
  }
}

/// The one line the artwork licence requires, and nothing more.
class _Colophon extends StatelessWidget {
  const _Colophon();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      link: true,
      label: context.l10n.artworkCredits,
      child: InkWell(
        onTap: () =>
            unawaited(launchUrl(Uri.base.resolve('intro/models/LICENSE.md'))),
        mouseCursor: context.platform.isPointer
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: Padding(
          padding: EdgeInsets.all(tokens.space8),
          child: ExcludeSemantics(
            child: Text(
              context.l10n.artworkCredits,
              style: context.type.meta.copyWith(color: tokens.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
