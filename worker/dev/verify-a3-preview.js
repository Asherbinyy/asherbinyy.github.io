/**
 * The other half of A3: the preview channel, and the release state.
 *
 * The public adapter does not exist yet, so this drives the editor's half
 * against a stand-in served from a genuinely different origin — the panel is
 * on `localhost`, the preview on `127.0.0.1`. Both sides' origin checks are
 * therefore doing real work rather than passing because everything happens to
 * be same-origin.
 *
 *   node worker/dev/serve.js 8788 &
 *   npm exec --yes --package=node@22 -- node worker/dev/verify-a3-preview.js
 */

import {base, captures, noise, openPanel, quiet, reporter} from './harness.js';

/// What the preview fixture says it rendered.
///
/// The panel and the preview are different origins on purpose, so the test
/// driving the panel cannot read into the frame -- that separation is the
/// thing being verified. The fixture reports to the harness instead.
const fromPreview = () =>
  fetch(`${base}/__preview-log`).then((response) => response.json());


const {check, finish} = reporter();

async function main() {
  const shot = await captures('2026-09-12-admin-a3-preview');
  const page = await openPanel();

  try {
    await page.eval("clickText('#rail .section', 'Off duty')");
    await quiet(page);
    await page.settle(2500);

    // --- the handshake ----------------------------------------------------
    const connected = await page.eval(`({
      state: $('previewState').textContent,
      classes: $('previewState').className,
      framed: Boolean(document.querySelector('#previewFrame iframe')),
      src: (document.querySelector('#previewFrame iframe') || {}).src,
    })`);
    check(
      'the preview is framed from the configured origin, with a session',
      connected.framed && /^http:\/\/127\.0\.0\.1:8788\/\?preview=1&session=[0-9a-f]{32}$/
        .test(connected.src),
      connected.src,
    );
    check(
      'the handshake completes and the draft is shown as rendered',
      /as the site would render it/.test(connected.state),
      connected.state + ' | ' + connected.classes,
    );
    await page.screenshot(shot('01-preview-connected.png'));

    // --- the draft actually crosses ---------------------------------------
    await page.eval("document.querySelector('#editor .row .open').click()");
    await quiet(page);
    await page.eval("setValue('f-interests-0-label-en', 'Bouldering')");
    await quiet(page);
    await page.settle(1200);
    const blocked = await page.eval(
      "document.querySelector('#previewFrame iframe').contentDocument === null",
    );
    check(
      'the preview really is a different origin, and the panel cannot read into it',
      blocked,
    );

    const carried = await fromPreview();
    check(
      'the edited draft reaches the preview and is rendered',
      carried.file === 'interests.json' && carried.text.includes('Bouldering'),
      JSON.stringify({file: carried.file, locale: carried.locale}),
    );
    check(
      'components are identified as "<file>:<path>", as agreed',
      Array.isArray(carried.componentIds) &&
        carried.componentIds.includes('interests.json:interests.0.label.en'),
      (carried.componentIds || []).slice(0, 3).join(', '),
    );

    // --- selection follows the editor -------------------------------------
    const selected = await fromPreview();
    check(
      'opening an entry tells the preview to scroll to it',
      typeof selected.asked === 'string' &&
        selected.asked.startsWith('interests.json:interests.0') &&
        typeof selected.chosen === 'string',
      JSON.stringify({asked: selected.asked, chosen: selected.chosen}),
    );
    await page.screenshot(shot('02-preview-selection.png'));

    // --- language ----------------------------------------------------------
    await page.eval("clickText('.langTabs button', 'Arabic')");
    await quiet(page);
    await page.settle(1000);
    check(
      'switching language tells the preview which one to render',
      (await fromPreview()).locale === 'ar',
      (await fromPreview()).locale,
    );
    await page.eval("clickText('.langTabs button', 'English')");
    await quiet(page);

    // --- a draft that would not render is not sent ------------------------
    await page.eval("setValue('f-interests-0-label-en', '')");
    await quiet(page);
    await page.settle(700);
    check(
      'an invalid draft is held back, and the panel says why',
      /Fix the problems/.test(await page.eval("$('previewState').textContent")),
      await page.eval("$('previewState').textContent"),
    );
    await page.eval("setValue('f-interests-0-label-en', 'Bouldering')");
    await quiet(page);
    await page.settle(900);
    check(
      'fixing it sends the draft again',
      /as the site would render it/.test(
        await page.eval("$('previewState').textContent"),
      ),
    );

    // --- nothing sensitive crosses ----------------------------------------
    const session = await page.eval(
      "sessionStorage.getItem('portfolio.admin.session')",
    );
    const received = await fromPreview();
    check(
      'no credential is in anything the preview received',
      typeof session === 'string' && session.length === 64 &&
        !received.raw.includes(session) &&
        !/authorization|Bearer /i.test(received.raw),
      received.raw.slice(0, 120),
    );

    // --- the outline is still there ---------------------------------------
    await page.eval("$('showOutline').click()");
    await page.settle(500);
    check(
      'the outline is still available beside the preview',
      await page.eval(
        "$('outlineWrap').hidden === false && $('previewWrap').hidden === true",
      ),
    );
    await page.eval("$('showPreview').click()");
    await page.settle(500);

    // --- the release state --------------------------------------------------
    await page.eval("clickText('#rail .section', 'Home')");
    await page.settle(2000);
    const release = await page.eval("$('editor').innerText");
    check(
      'the dashboard says what the site is actually serving',
      /What the site is serving/.test(release),
      release.slice(0, 100),
    );
    check(
      'and does not call it published when nothing serves a release file',
      /No release file is being served yet/.test(release) &&
        !/Published to HTML/.test(release),
      (release.match(/No release file[^\n]*/) || [''])[0],
    );
    check(
      'it shows the revision a build from this content would produce',
      /[0-9a-f]{16}/.test(release),
    );
    await page.screenshot(shot('03-release-state.png'));

    const noisy = noise(page);
    check(
      'the browser reported no errors',
      noisy.length === 0,
      noisy.map((entry) => entry.text).join(' | ').slice(0, 300),
    );
  } finally {
    await page.close();
  }

  process.exit(finish() ? 0 : 1);
}

main().catch((error) => {
  process.stderr.write(String(error && error.stack ? error.stack : error) + '\n');
  process.exit(1);
});
