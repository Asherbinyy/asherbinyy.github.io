import 'package:material_ui/material_ui.dart';

import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

/// The one easter egg, per roadmap 3.4.
///
/// **`CQ` is amateur radio's general call — "calling anyone, anywhere".** Type
/// it anywhere on the ground station and the station answers: a short Morse
/// burst in amber, then a single line of telemetry, then it goes quiet again.
///
/// Discoverable, not intrusive. It is invisible until sought, costs nothing to
/// anyone who never finds it, moves nothing on the page — the response occupies
/// space that is already reserved, so nothing reflows — and answers only to a
/// two-letter sequence a viewer would only type on purpose. Anyone fluent in
/// the metaphor this whole site is built on already knows the word.
///
/// It obeys reduced motion like everything else: no blinking, just the line.
class CqResponse extends StatefulWidget {
  /// Listens for the call and renders the answer.
  const CqResponse({super.key});

  /// Morse for the owner's initials, AE — dot-dash, dot.
  ///
  /// True to the medium: a real station answers a CQ with its own callsign.
  static const List<bool> callsign = [
    false, true, // A: dot dash
    false, // E: dot
  ];

  /// How long the answer stays up before the station goes quiet again.
  static const Duration dwell = Duration(seconds: 6);

  @override
  State<CqResponse> createState() => _CqResponseState();
}

class _CqResponseState extends State<CqResponse> {
  /// How much of "cq" has been typed so far.
  int _matched = 0;

  bool _isAnswering = false;

  @override
  void initState() {
    super.initState();
    // A global handler rather than a focused listener. A `KeyboardListener`
    // only hears keys while its node holds focus, and this must not be a stop
    // on the keyboard tour — an easter egg that steals a tab position is
    // intrusive, which is the one thing roadmap 3.4 says it must not be.
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  /// Reserved so an answer never reflows the page around it.
  static const double _height = 24;

  /// Returns false always: the egg listens, and never swallows a keystroke
  /// meant for the page underneath it.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final expected = _matched == 0
        ? LogicalKeyboardKey.keyC
        : LogicalKeyboardKey.keyQ;
    if (event.logicalKey == expected) {
      _matched++;
      if (_matched == 2) {
        _matched = 0;
        _answer();
      }
    } else {
      // A wrong key resets, except a fresh "c" which starts the call again.
      _matched = event.logicalKey == LogicalKeyboardKey.keyC ? 1 : 0;
    }
    return false;
  }

  void _answer() {
    if (_isAnswering) return;
    setState(() => _isAnswering = true);
    Future<void>.delayed(CqResponse.dwell, () {
      if (mounted) setState(() => _isAnswering = false);
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: _height,
      child: AnimatedOpacity(
        opacity: _isAnswering ? 1 : 0,
        duration: ReducedMotion.duration(context, Motion.standard),
        curve: MotionCurves.emphasized,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final isDash in CqResponse.callsign) ...[
              _Mark(isDash: isDash),
              SizedBox(width: tokens.space4),
            ],
            SizedBox(width: tokens.space8),
            Text(
              context.l10n.stationCqResponse,
              style: context.type.telemetryS.copyWith(color: tokens.beacon),
            ),
          ],
        ),
      ),
    );
  }
}

/// One Morse element: a dot is square, a dash is three times as wide.
class _Mark extends StatelessWidget {
  const _Mark({required this.isDash});

  final bool isDash;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: isDash ? tokens.space12 : tokens.space4,
      height: tokens.space4,
      child: ColoredBox(color: tokens.beacon),
    );
  }
}
