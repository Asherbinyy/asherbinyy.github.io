/**
 * The browser half of Codex's merge review: AR-3, AR-4 and AR-6.
 *
 * Each of these is a race, so each is reproduced by holding a write open while
 * something else happens. The harness delays uploads and publishes on request;
 * the panel is unchanged.
 *
 *   UPLOAD_DELAY=2000 PUBLISH_DELAY=1500 node worker/dev/serve.js 8788 &
 *   npm exec --yes --package=node@22 -- node worker/dev/verify-review-fixes.js
 */

import {base, captures, noise, openPanel, quiet, reporter, token} from './harness.js';

const {check, finish} = reporter();

const sheetButton = (name) =>
  `[...document.querySelectorAll('#sheetBody button')]` +
  `.find((b) => b.textContent.trim().startsWith(${JSON.stringify(name)}))`;

async function main() {
  const shot = await captures('2026-09-12-admin-review-fixes');
  const page = await openPanel();

  try {
    // --- AR-3: a delayed upload lands where it started --------------------
    await page.eval("clickText('#rail .section', 'Profile')");
    await quiet(page);
    await page.eval(
      "pngBytes(120, 90).then((b) => attachFile('f-portrait-src-file', b, 'p.png', 'image/png'))",
      true,
    );
    // Straight to another document while it is still uploading.
    await page.eval("clickText('#rail .section', 'Off duty')");
    await quiet(page);
    await page.settle(3000);

    const landed = await page.eval(`(async () => {
      const read = async (file) => {
        const response = await fetch('/v1/admin/validate', {
          method: 'POST',
          headers: {
            'content-type': 'application/json',
            authorization: 'Bearer ' + sessionStorage.getItem('portfolio.admin.session'),
          },
          body: JSON.stringify({file, document: {}}),
        });
        await response.json();
      };
      await read('interests.json');
      return {
        status: document.getElementById('status').textContent,
        railPips: [...document.querySelectorAll('#rail .section')].map((s) => {
          const pip = s.querySelector('.pip');
          return s.textContent.trim() + (pip && !pip.hidden ? '*' : '');
        }),
      };
    })()`, true);
    check(
      'the upload marked Profile as changed, not the page that was opened after it',
      landed.railPips.some((entry) => entry === 'Profile*') &&
        !landed.railPips.some((entry) => entry === 'Off duty*'),
      landed.railPips.join(', '),
    );

    await page.eval("clickText('#rail .section', 'Profile')");
    await quiet(page);
    check(
      'and the picture is in the field it was started from',
      /^\/v1\/media\/[0-9a-f]{32}$/.test(
        await page.eval("$('f-portrait-src').value"),
      ),
      await page.eval("$('f-portrait-src').value"),
    );
    await page.screenshot(shot('01-upload-landed-on-profile.png'));

    // --- AR-3: a delayed upload follows its entry when the list moves -----
    await page.eval("clickText('#rail .section', 'Work')");
    await quiet(page);
    const firstName = await page.eval(
      "document.querySelector('#editor .row .t').textContent.trim()",
    );
    await page.eval("document.querySelector('#editor .row .open').click()");
    await quiet(page);
    await page.eval(
      "pngBytes(64, 64).then((b) => attachFile('f-apps-0-screenshot-file', b, 's.png', 'image/png'))",
      true,
    );
    // Back to the list and move that entry down while the upload is in flight.
    await page.eval("document.querySelector('.crumbs button').click()");
    await quiet(page);
    await page.eval(
      "document.querySelectorAll('#editor .row')[0].querySelector('[aria-label^=\"Move\"][aria-label$=\"down\"]').click()",
    );
    await quiet(page);
    await page.settle(3000);

    const moved = await page.eval(`(() => {
      const rows = [...document.querySelectorAll('#editor .row .t')]
        .map((n) => n.textContent.trim());
      return {rows};
    })()`);
    check(
      'the entry did move',
      moved.rows[1] === firstName,
      moved.rows.join(' | '),
    );

    await page.eval(
      "document.querySelectorAll('#editor .row')[1].querySelector('.open').click()",
    );
    await quiet(page);
    const followed = await page.eval(`({
      name: document.querySelector('#editor h2').textContent,
      screenshot: $('f-apps-1-screenshot').value,
    })`);
    check(
      'the picture followed its entry rather than staying at the old position',
      followed.name === firstName &&
        /^\/v1\/media\/[0-9a-f]{32}$/.test(followed.screenshot),
      JSON.stringify(followed),
    );

    await page.eval("document.querySelector('.crumbs button').click()");
    await quiet(page);
    const other = await page.eval("$('f-apps-0-screenshot')");
    check(
      'and nothing was written into whatever took its place',
      other === null || other === undefined,
    );
    await page.screenshot(shot('02-upload-followed-reorder.png'));

    // --- AR-3: an entry removed mid-upload is reported, not guessed at ----
    await page.eval("window.confirm = () => true");
    await page.eval("document.querySelectorAll('#editor .row')[2].querySelector('.open').click()");
    await quiet(page);
    const doomed = await page.eval("document.querySelector('#editor h2').textContent");
    await page.eval(
      "pngBytes(48, 48).then((b) => attachFile('f-apps-2-screenshot-file', b, 'x.png', 'image/png'))",
      true,
    );
    await page.eval("document.querySelector('.crumbs button').click()");
    await quiet(page);
    await page.eval(
      "document.querySelectorAll('#editor .row')[2].querySelector('[aria-label^=\"Remove\"]').click()",
    );
    await quiet(page);
    await page.settle(3000);
    check(
      'removing the entry mid-upload is said out loud rather than written somewhere else',
      /field it was for is gone/i.test(
        await page.eval("$('status').textContent"),
      ),
      await page.eval("$('status').textContent"),
    );
    check(
      'and the entry really is gone rather than resurrected',
      !(await page.eval("$('editor').innerText")).includes(doomed),
    );

    // --- AR-6: only the exact validated draft crosses to the preview ------
    await page.eval("clickText('#rail .section', 'Off duty')");
    await quiet(page);
    await page.eval("document.querySelector('#editor .row .open').click()");
    await quiet(page);
    await page.settle(1500);
    const beforeEdit = await fetch(`${base}/__preview-log`).then((r) => r.json());

    // Empty the required label and switch language immediately, inside the
    // validation debounce. This used to send the broken draft and call it
    // rendered.
    await page.eval("setValue('f-interests-0-label-en', '')");
    await page.eval("clickText('.langTabs button', 'Arabic')");
    // Sampled inside the validation debounce, which is the window the defect
    // lived in: the language switch asks the preview to re-render, and the
    // only answer on hand describes the draft from before the field was
    // emptied.
    await page.settle(120);
    const midRace = await page.eval("$('previewState').textContent");
    const midSent = await fetch(`${base}/__preview-log`).then((r) => r.json());
    check(
      'nothing crosses while the draft is still being checked',
      midSent.raw === beforeEdit.raw && !/as the site would render it/.test(midRace),
      midRace,
    );

    await page.settle(700);
    const during = await page.eval("$('previewState').textContent");
    const sent = await fetch(`${base}/__preview-log`).then((r) => r.json());
    check(
      'the invalid draft never crossed the boundary',
      sent.raw === beforeEdit.raw,
      during,
    );
    check(
      'and the panel does not claim it is showing the draft',
      !/as the site would render it/.test(during),
      during,
    );
    await page.screenshot(shot('03-invalid-draft-held-back.png'));

    await quiet(page);
    await page.settle(900);
    check(
      'once it is checked, the panel reports the real problem',
      /Fix the problems/.test(await page.eval("$('previewState').textContent")),
      await page.eval("$('previewState').textContent"),
    );

    await page.eval("clickText('.langTabs button', 'English')");
    await page.eval("setValue('f-interests-0-label-en', 'Walking')");
    await quiet(page);
    await page.settle(900);
    check(
      'and a valid draft goes over again',
      /as the site would render it/.test(
        await page.eval("$('previewState').textContent"),
      ),
    );

    // --- AR-4: a dirty draft keeps its base across reauthentication -------
    await page.eval("setValue('f-interests-0-label-en', 'Mine, unpublished')");
    await quiet(page);

    // Someone else publishes while this draft is open.
    const theirs = await fetch(`${base}/assets/assets/content/interests.json`)
      .then((response) => response.json());
    theirs.interests[0].label.en = 'Theirs, published';
    const published = await fetch(`${base}/v1/admin/content/interests.json`, {
      method: 'PUT',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
        'x-base-revision': '0',
      },
      body: JSON.stringify(theirs),
    });
    check('another writer published', published.status === 200);

    // End the session, forcing the panel to sign in again.
    const held = await page.eval(
      "sessionStorage.getItem('portfolio.admin.session')",
    );
    await fetch(`${base}/v1/admin/session`, {
      method: 'DELETE',
      headers: {authorization: `Bearer ${held}`},
    });
    await page.eval("$('history').click()");
    await page.settle(900);
    await page.eval(`setValue('reauthPassword', ${JSON.stringify(token)})`);
    await page.eval("$('reauthGo').click()");
    await page.settle(1800);

    const afterReauth = await page.eval(`({
      draft: $('f-interests-0-label-en').value,
      changes: $('changeCount').textContent,
      divergence: $('divergence').hidden ? '' : $('divergence').textContent,
    })`);
    check(
      'the draft survived signing back in',
      afterReauth.draft === 'Mine, unpublished' &&
        /change/.test(afterReauth.changes),
      JSON.stringify(afterReauth),
    );
    check(
      'and the panel says someone else has published',
      /published revision 1/.test(afterReauth.divergence),
      afterReauth.divergence,
    );
    await page.screenshot(shot('04-divergence-after-reauth.png'));

    await page.eval("$('publish').click()");
    await page.settle(1200);
    await page.eval(sheetButton('Publish') + '.click()');
    await page.settle(1500);
    const conflicted = await page.eval(`({
      title: $('sheetTitle').textContent,
      body: $('sheetBody').innerText,
    })`);
    check(
      'publishing on the stale base is refused rather than overwriting them',
      /changed this page/i.test(conflicted.title),
      conflicted.title,
    );
    check(
      'the conflict shows their version, which was never lost',
      /Theirs, published/.test(conflicted.body),
      conflicted.body.slice(0, 160),
    );
    await page.screenshot(shot('05-stale-base-conflict.png'));

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
