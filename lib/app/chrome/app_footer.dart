import 'package:material_ui/material_ui.dart';

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
/// terminates the content column so a short page does not simply stop. It
/// closes the page from the end of the scroll rather than sitting fixed under
/// the viewport, where it cost every screen 48 pixels -- on a phone, with the
/// two-row header, a fifth of the screen or more was chrome. An empty bar is
/// the honest result of having nothing to say here, and inventing a tagline to
/// fill it would be exactly the kind of copy the owner objected to.
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
      // Nothing in it. The artwork credit that briefly lived here has moved
      // to the repository's README, where the licence is honoured in the
      // place that actually describes the work: the owner asked for a clean
      // page and CC BY-SA does not require the attribution to be on the page
      // itself, only that it be given.
      child: SizedBox(height: tokens.footerHeight, width: double.infinity),
    );
  }
}
