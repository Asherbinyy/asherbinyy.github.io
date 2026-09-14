# Game design — Flutter F3

Updated 2026-09-11 from the original owner conversations and current request.
Detailed execution and acceptance: [F3](19-FLUTTER-ENHANCEMENT-PLAN.md#f3--game-feel-character-and-progression).

## Purpose

A standalone fun experience inspired by Ice Tower, with original Egyptian art and a satisfying movement/reward loop. No career facts, CV unlocks or work-related rewards. Those earlier requirements were explicitly withdrawn by the owner.

## Current state

The game opens full-screen from `/courtyard`. The implementation lives in `lib/features/courtyard/game/` and `lib/core/painting/ascent_painter.dart`.

It has static, cracked and moving platforms, manual Space/tap jumping from the ground, stronger jumps on upward wall contact, a rising floor, level numbers, score and sound/restart/exit controls. The owner rejects the current feel and art. An implementation existing is not completion.

The old continuous-auto-bounce specification is no longer current. The latest explicit original request replaced it with Space/tap. The owner has now asked for more bouncing/springiness; the current plan keeps manual Space/tap and improves spring through physics and feedback, to be reviewed in a playable prototype.

## Proposed movement

Keep manual input unless the owner chooses otherwise. Add horizontal momentum, jump buffering, a small coyote window, variable jump height, predictable wall kicks and elastic landing animation. Compression/rebound should communicate spring without stealing the player's decision to jump.

Prototype this with simple art first. Tune acceleration, apex, landing tolerance and wall behavior by playing on keyboard and touch. No physics constants are prescribed here before that prototype is reviewed.

## Character and world

The owner requests an Egyptian stick-like humanoid with a gold headpiece. It needs a readable silhouette and distinct jump, fall, turn and landing poses. The September 13 local restoration replaces it with the requested humanoid and a gold nemes.

Use a layered shaft with architectural scale, legible platforms and level-specific visual changes. Start with generous placement, introduce moving/crumbling platforms clearly, then combine them with the rising hazard. Generated platform paths must be reachable with the actual movement model.

## Rewards

Wall-kick bonus, consecutive-landing combo, collectibles or earned score, personal-best feedback and quick retry. A particle ring is feedback, not a complete reward. Rewards should be understandable during play and never obscure the next landing.

The exact reward balance and level count belong to the prototype, not invented claims about a supposedly finished game. The earlier CV summit/mask and offline duplicate game are not mandatory scope in the new milestones.

## Input, audio and accessibility

- Keyboard and touch get equally usable control schemes. Space is captured only by the focused game, not the background document.
- Keep sound/restart/exit controls visible and clear of play. Restore focus/scroll after exit.
- Pause on blur; stop ticking and audio on exit. Audio starts only after a player gesture and has a mute control.
- Reduced motion removes shake, particles and parallax; deliberate gameplay remains operable.
- Provide a discoverable practice/assistance option, without filling the default screen with controls.
- No viewer collection or online leaderboard. Any persistence follows the repository's privacy constraints.

## Completion

Review a playable movement prototype, then full runs through early/middle/late difficulty with final art. Verify keyboard, touch, focus, lifecycle and fair platform generation. Measure performance in a browser; physical phone acceptance belongs to F9. Passing collision or painter tests alone cannot establish that the game is enjoyable.

## September 13 implemented restoration

Manual input retained. Horizontal acceleration/braking, 140ms buffered/coyote timing, variable jump height, one launch per held press, and damped landing squash are implemented locally. Holding a key no longer repeats jumps automatically. Wall kicks retain their bonus; short taps deliberately reach less height than a held jump. Reduced motion suppresses the squash and entrance sweep while preserving essential gameplay movement.

The current score is still altitude and the best is memory-only for the open stage. Cloud ranking, nickname, rewards/combos and richer level patterns remain unimplemented; see `26-GAME-LEADERBOARD-CONTRACT.md`. Do not treat restoring the controls/character as completion of F3.
