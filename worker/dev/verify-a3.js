/**
 * Phase A3 in a browser: review, cancel, sources, conflicts, history.
 *
 * The preview half of A3 is not here, and cannot be: it needs the public
 * adapter Codex owns. What is here is everything about deciding to publish and
 * being able to undo it.
 *
 *   node worker/dev/serve.js 8788 &
 *   npm exec --yes --package=node@22 -- node worker/dev/verify-a3.js
 */

import {base, captures, noise, openPanel, quiet, reporter, token} from './harness.js';

const {check, finish} = reporter();

/// The sheet's own buttons, by their visible name.
const sheetButton = (name) =>
  `[...document.querySelectorAll('#sheetBody button')]` +
  `.find((b) => b.textContent.trim().startsWith(${JSON.stringify(name)}))`;

async function main() {
  const shot = await captures('2026-09-12-admin-a3');
  const page = await openPanel();

  try {
    // --- review shows what would change, and cancel changes nothing -------
    await page.eval("clickText('#rail .section', 'Off duty')");
    await quiet(page);
    // Interests are a compact list, so the entry has to be opened before its
    // fields exist. That is the A1 behaviour this phase builds on.
    await page.eval("document.querySelector('#editor .row .open').click()");
    await quiet(page);
    await page.eval("setValue('f-interests-0-label-en', 'Hiking')");
    await quiet(page);

    await page.eval("$('publish').click()");
    await page.settle(900);
    const review = await page.eval(`(() => ({
      open: $('sheet').open,
      title: $('sheetTitle').textContent,
      changes: [...document.querySelectorAll('#sheetBody .group h3')]
        .map((n) => n.textContent),
      sourceBox: Boolean($('sourceNote')),
      saysWhatIsNotUpdated: /CV, the Brief and the page/.test($('sheetBody').innerText),
    }))()`);
    check(
      'review opens a sheet listing every value that would change',
      review.open && review.changes.includes('interests.0.label.en'),
      JSON.stringify(review.changes),
    );
    check(
      'a change with no figure in it is not asked for a source',
      review.sourceBox === false,
    );
    check(
      'the sheet says what publishing does not update',
      review.saysWhatIsNotUpdated,
    );
    await page.screenshot(shot('01-review-sheet.png'));

    await page.eval(sheetButton('Cancel') + '.click()');
    await page.settle(500);
    const afterCancel = await page.eval(`(async () => {
      const read = await fetch('/v1/admin/content', {
        headers: {authorization: 'Bearer ' + ${JSON.stringify(token)}},
      }).then((r) => r.json());
      return {
        sheet: $('sheet').open,
        published: read.published,
        draftKept: $('f-interests-0-label-en').value,
      };
    })()`, true);
    check(
      'cancelling publishes nothing and keeps the draft',
      afterCancel.sheet === false &&
        afterCancel.published.length === 0 &&
        afterCancel.draftKept === 'Hiking',
      JSON.stringify(afterCancel),
    );

    // --- discarding -------------------------------------------------------
    await page.eval('window.confirm = () => true');
    await page.eval("$('discard').click()");
    await quiet(page);
    check(
      'discarding goes back to what the site shows',
      (await page.eval("$('f-interests-0-label-en').value")) === 'Walking' &&
        /No changes/.test(await page.eval("$('changeCount').textContent")),
    );

    // --- publishing, and the revision it becomes --------------------------
    await page.eval("setValue('f-interests-0-label-en', 'Hiking')");
    await quiet(page);
    await page.eval("$('publish').click()");
    await page.settle(800);
    await page.eval(sheetButton('Publish') + '.click()');
    await page.settle(1200);
    const published = await page.eval(`({
      status: $('status').textContent,
      source: $('source').textContent,
      changes: $('changeCount').textContent,
    })`);
    check(
      'publishing from the sheet stores it as revision 1',
      /revision 1/.test(published.status) && /revision 1/.test(published.source),
      JSON.stringify(published),
    );

    // --- a figure cannot go out without a source --------------------------
    await page.eval("clickText('#rail .section', 'Profile')");
    await quiet(page);
    await page.eval("setValue('f-name-en', 'Test Person II')");
    await quiet(page);
    await page.eval("$('publish').click()");
    await page.settle(900);
    const asked = await page.eval(`(() => ({
      sourceBox: Boolean($('sourceNote')),
      reason: $('sheetBody').innerText,
    }))()`);
    check(
      'a first publish asks for a source for the figures on the page',
      asked.sourceBox && /never been given a source/.test(asked.reason),
      asked.reason.slice(0, 120),
    );
    await page.screenshot(shot('02-source-required.png'));

    await page.eval(sheetButton('Publish') + '.click()');
    await page.settle(600);
    check(
      'publishing with the source box empty is refused, and the sheet stays',
      await page.eval(
        "$('sheet').open && /without a source/.test($('status').textContent)",
      ),
    );

    await page.eval("setValue('sourceNote', 'Fixture, for verification only')");
    await page.eval(sheetButton('Publish') + '.click()');
    await page.settle(1200);
    check(
      'with a source it goes out',
      /revision 1/.test(await page.eval("$('status').textContent")),
      await page.eval("$('status').textContent"),
    );

    // --- two tabs ---------------------------------------------------------
    // Someone else publishes revision 2 while this panel still believes it is
    // looking at revision 1.
    await fetch(`${base}/v1/admin/content/profile.json`, {
      method: 'PUT',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
        'x-change-note': 'Another tab',
      },
      body: JSON.stringify(
        await fetch(`${base}/v1/content/profile.json`, {
          headers: {origin: base},
        })
          .then((r) => r.json())
          .then((held) => ({...held, location: {en: 'Somewhere else'}})),
      ),
    });

    await page.eval("setValue('f-greeting-en', 'Good afternoon')");
    await quiet(page);
    await page.eval("$('publish').click()");
    await page.settle(900);
    await page.eval(sheetButton('Publish') + '.click()');
    await page.settle(1200);
    const conflict = await page.eval(`(() => ({
      title: $('sheetTitle').textContent,
      body: $('sheetBody').innerText,
      buttons: [...document.querySelectorAll('#sheetBody button')]
        .map((b) => b.textContent.trim()),
    }))()`);
    check(
      'publishing over someone else stops and says so',
      /changed this page/i.test(conflict.title) &&
        /revision 1/.test(conflict.body) && /revision 2|now on 2/.test(conflict.body),
      conflict.body.slice(0, 160),
    );
    check(
      'the conflict offers both ways out by name',
      conflict.buttons.some((name) => /Throw mine away/.test(name)) &&
        conflict.buttons.some((name) => /Keep mine/.test(name)),
      conflict.buttons.join(' | '),
    );
    await page.screenshot(shot('03-conflict.png'));

    await page.eval(sheetButton('Keep mine') + '.click()');
    await quiet(page);
    const rebased = await page.eval(`({
      greeting: $('f-greeting-en').value,
      source: $('source').textContent,
      changes: $('changeCount').textContent,
    })`);
    check(
      'keeping mine holds the edit and moves onto their revision',
      rebased.greeting === 'Good afternoon' && /revision 2/.test(rebased.source),
      JSON.stringify(rebased),
    );

    await page.eval("$('publish').click()");
    await page.settle(900);
    await page.eval(sheetButton('Publish') + '.click()');
    await page.settle(1200);
    check(
      'the rebased draft then publishes cleanly',
      /revision 3/.test(await page.eval("$('status').textContent")),
      await page.eval("$('status').textContent"),
    );

    // --- history and going back -------------------------------------------
    await page.eval("$('history').click()");
    await page.settle(900);
    const history = await page.eval(`(() => ({
      title: $('sheetTitle').textContent,
      entries: [...document.querySelectorAll('#sheetBody .group h3')]
        .map((n) => n.textContent),
      backButtons: [...document.querySelectorAll('#sheetBody button')]
        .filter((b) => /Go back/.test(b.textContent)).length,
    }))()`);
    check(
      'the history lists every revision, newest first, marking the current one',
      history.entries.length === 3 && /current/.test(history.entries[0]),
      history.entries.join(' | '),
    );
    check('every revision but the current one can be gone back to', history.backButtons === 2);
    await page.screenshot(shot('04-history.png'));

    await page.eval(
      `[...document.querySelectorAll('#sheetBody button')]
        .filter((b) => /Go back/.test(b.textContent)).pop().click()`,
    );
    await page.settle(1500);
    const rolled = await page.eval(`({
      status: $('status').textContent,
      greeting: $('f-greeting-en').value,
    })`);
    check(
      'going back puts the old document on the site as a new revision',
      /revision 1 is back, as revision 4/i.test(rolled.status) &&
        rolled.greeting === "Hello, I'm Testy.",
      JSON.stringify(rolled),
    );

    const onSite = await fetch(`${base}/v1/content/profile.json`, {
      headers: {origin: base},
    });
    check(
      'the site receives the restored document and its revision',
      (await onSite.json()).greeting.en === "Hello, I'm Testy." &&
        onSite.headers.get('x-content-revision') === '4',
      onSite.headers.get('x-content-revision'),
    );

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
