import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// The 48px footer.
///
/// It carried a coordinate readout until milestone 4, derived from the current
/// role's latitude. Task 4.9 removed it on the owner's instruction: it
/// introduced him by a map reference, which is the opposite of what the site
/// is now for. The row keeps its height and its single location line.
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
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.platform.gutter,
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  context.l10n.footerLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.meta,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
