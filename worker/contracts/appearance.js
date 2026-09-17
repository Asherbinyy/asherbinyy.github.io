/**
 * The renderers the site knows how to draw.
 *
 * Deliberately a duplicate of `lib/app/theme/appearance_contract.dart`. The
 * admin panel stores an appearance against the site and the app reads it back;
 * those are two programs that ship separately, so the only way they can agree
 * is to write the list twice and hold both to one fixture.
 *
 * `contracts/fixtures/appearance-v1.json` is that fixture. Both sides assert
 * against it and neither generates it, so adding an id here without adding it
 * there fails the Worker's tests, and adding it there without adding it in
 * Dart fails the app's.
 *
 * **An unknown id is reported, never defaulted.** Falling back to the default
 * renderer makes an unsupported appearance indistinguishable from the
 * supported one: the owner picks something, sees the site unchanged, and
 * cannot tell whether it failed or whether that is simply how it looks.
 */

/** The generation of this allowlist. Bump it on any change to `SUPPORTED`. */
export const APPEARANCE_VERSION = 1;

/**
 * Every renderer the app can draw, by stored id.
 *
 * The two that exist. The handoff is explicit that no unrequested presets are
 * to be invented while the controls are wired, so this is a list of what is
 * real rather than of what is possible.
 */
export const SUPPORTED = ['nocturne', 'daybreak'];

/** Whether `id` names a renderer the app can draw. */
export function supportsAppearance(id) {
  return typeof id === 'string' && SUPPORTED.includes(id);
}

/**
 * Reads a stored id and says what it is.
 *
 * `unset` is not an error — nothing has been chosen and the app's own default
 * applies. `unsupported` carries the id it could not use, because "unsupported
 * appearance" is a shrug and "unsupported appearance: papyrus-v2" is something
 * the owner can act on.
 */
export function resolveAppearance(id) {
  if (id === null || id === undefined || id === '') return {state: 'unset'};
  if (!supportsAppearance(id)) return {state: 'unsupported', id: String(id)};
  return {state: 'supported', id};
}
