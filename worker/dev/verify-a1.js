/**
 * Opens the panel in Chrome and uses it, the way the owner would.
 *
 * A passing unit test says the Worker answers correctly. It does not say the
 * editor is usable, that a draft survives a click, that a label is attached
 * to its box, or that anything is legible on a phone. This does those, and
 * leaves screenshots behind so the claim can be checked rather than believed.
 *
 *   node worker/dev/serve.js 8788 &
 *   npm exec --yes --package=node@22 -- node worker/dev/verify-a1.js
 */


import {captures, helpers, noise, quiet, reporter} from './harness.js';
import {launch} from './browser.js';

const base = process.env.ADMIN_BASE ?? 'http://localhost:8788';
const token = process.env.ADMIN_TOKEN ??
  'local-development-token-' + 'x'.repeat(24);
const {check, finish} = reporter();


async function main() {
  const shot = await captures('2026-09-11-admin-a1');
  const page = await launch({width: 1440, height: 900});

  try {
    await page.goto(base + '/admin');
    await page.eval(helpers);

    // --- signing in --------------------------------------------------------
    await page.eval(`setValue('token', ${JSON.stringify(token)})`);
    await page.eval("$('unlock').click()");
    await page.settle(1200);
    check(
      'the panel opens with a valid token',
      await page.eval("$('frame').classList.contains('on')"),
    );

    // The panel opens on Home from A6 onwards; these checks are about the
    // editing side of it.
    await page.eval("clickText('#rail .section', 'Profile')");
    await page.settle(500);

    // --- the layout the owner asked for ------------------------------------
    const layout = await page.eval(`(() => {
      const rail = $('rail').getBoundingClientRect();
      const editor = $('editorPane').getBoundingClientRect();
      const outline = $('previewPane').getBoundingClientRect();
      return {
        rail: Math.round(rail.width),
        editor: Math.round(editor.width),
        outline: Math.round(outline.width),
        ordered: rail.right <= editor.left + 1 && editor.right <= outline.left + 1,
        sections: [...document.querySelectorAll('#rail .section')]
          .map((node) => node.textContent.trim()),
      };
    })()`);
    check(
      'sections, editor and a third column sit side by side at 1440',
      layout.ordered && layout.rail > 100 && layout.outline > 200,
      JSON.stringify(layout),
    );
    check(
      'all five documents are listed as sections',
      ['Profile', 'Work', 'Journey', 'Education', 'Off duty'].every((name) =>
        layout.sections.includes(name)),
      layout.sections.join(', '),
    );
    check(
      'the interface is not called Nocturne',
      !(await page.eval('document.body.innerText')).match(/nocturne/i),
    );
    await page.screenshot(shot('01-profile-desktop.png'));

    // --- labels and keyboard ----------------------------------------------
    const unlabelled = await page.eval(`(() => {
      const controls = [...document.querySelectorAll(
        '#editor input, #editor textarea, #editor select')];
      return controls
        .filter((node) => node.type !== 'file')
        .filter((node) => !node.getAttribute('aria-label'))
        .filter((node) => !node.id ||
          !document.querySelector('label[for="' + CSS.escape(node.id) + '"]'))
        .map((node) => node.outerHTML.slice(0, 70));
    })()`);
    check(
      'every control on the page has a label attached to it',
      unlabelled.length === 0,
      unlabelled.join(' | '),
    );

    // --- typing survives a validation round trip ---------------------------
    await page.eval("$('f-greeting-en').focus(); $('f-greeting-en').value = '';");
    await page.eval(
      "$('f-greeting-en').dispatchEvent(new Event('input', {bubbles: true}))",
    );
    await page.settle(200);
    await page.type('Good evening');
    await quiet(page);
    const typing = await page.eval(`({
      value: $('f-greeting-en').value,
      focused: document.activeElement.id,
      caret: document.activeElement.selectionStart,
    })`);
    check(
      'the caret stays put while the draft is being checked',
      typing.value === 'Good evening' &&
        typing.focused === 'f-greeting-en' &&
        typing.caret === 'Good evening'.length,
      JSON.stringify(typing),
    );

    // --- a draft survives leaving the page ---------------------------------
    await page.eval("clickText('#rail .section', 'Work')");
    await page.settle(400);
    const away = await page.eval(`({
      heading: document.querySelector('#editor h2').textContent,
      pip: !document.querySelector('#rail .section .pip').hidden,
    })`);
    check('another section opens', away.heading === 'Work', away.heading);
    check('the section left behind is marked as having unsaved work', away.pip);

    await page.eval("clickText('#rail .section', 'Profile')");
    await page.settle(400);
    check(
      'the draft is still there after navigating away and back',
      (await page.eval("$('f-greeting-en').value")) === 'Good evening',
    );

    // --- compact lists that open ------------------------------------------
    await page.eval("clickText('#rail .section', 'Work')");
    await page.settle(400);
    const list = await page.eval(`(() => {
      const rows = [...document.querySelectorAll('#editor .row')];
      return {
        rows: rows.length,
        tallest: Math.max(...rows.map((r) => Math.round(r.getBoundingClientRect().height))),
        titles: rows.map((r) => r.querySelector('.t').textContent.trim()),
      };
    })()`);
    check(
      'applications are compact rows, not stacked forms',
      list.rows === 3 && list.tallest < 90,
      JSON.stringify(list),
    );
    await page.screenshot(shot('02-work-list-desktop.png'));

    await page.eval("document.querySelector('#editor .row .open').click()");
    await page.settle(400);
    const opened = await page.eval(`({
      crumbs: [...document.querySelectorAll('.crumbs li')].map((n) => n.textContent.trim()),
      heading: document.querySelector('#editor h2').textContent,
      hash: location.hash,
    })`);
    check(
      'a row opens as its own panel with a way back',
      opened.heading === 'Example One' && opened.crumbs.length === 2,
      JSON.stringify(opened),
    );
    await page.screenshot(shot('03-work-item-desktop.png'));

    await page.eval("document.querySelector('.crumbs button').click()");
    await page.settle(300);
    check(
      'the breadcrumb goes back to the list',
      (await page.eval("document.querySelector('#editor h2').textContent")) === 'Work',
    );

    // --- adding, reordering, removing -------------------------------------
    await page.eval("clickText('#editor .listFoot button', 'Add an application')");
    await quiet(page);
    const added = await page.eval(`({
      heading: document.querySelector('#editor h2').textContent,
      problems: $('problemCount').textContent,
    })`);
    check(
      'adding an entry opens it and says what it still needs',
      added.heading.startsWith('Entry 4') && /problem/.test(added.problems),
      JSON.stringify(added),
    );
    await page.eval("document.querySelector('.crumbs button').click()");
    await page.settle(300);
    await page.eval(
      "document.querySelectorAll('#editor .row')[3].querySelector('[aria-label^=\"Move\"]').click()",
    );
    await page.settle(300);
    const order = await page.eval(
      "[...document.querySelectorAll('#editor .row .t')].map((n) => n.textContent.trim())",
    );
    check(
      'an entry can be moved up the list',
      order[2].startsWith('Entry'),
      order.join(' | '),
    );
    await page.eval(`(() => {
      window.confirm = () => true;
      document.querySelectorAll('#editor .row')[2]
        .querySelector('[aria-label^="Remove"]').click();
    })()`);
    await page.settle(400);
    check(
      'an entry can be removed',
      (await page.eval("document.querySelectorAll('#editor .row').length")) === 3,
    );

    // --- English and Arabic ------------------------------------------------
    await page.eval("clickText('#rail .section', 'Profile')");
    await page.settle(400);
    const tabs = await page.eval(`(() => {
      const list = $('editor').querySelector('.langTabs');
      const buttons = [...list.querySelectorAll('button')];
      const boxes = buttons.map((b) => b.getBoundingClientRect());
      return {
        orientation: list.getAttribute('aria-orientation'),
        stacked: boxes[1].top >= boxes[0].bottom - 1,
        labels: buttons.map((b) => b.textContent.trim()),
      };
    })()`);
    check(
      'the language tabs are stacked one above the other',
      tabs.stacked && tabs.orientation === 'vertical',
      JSON.stringify(tabs),
    );

    await page.eval("clickText('.langTabs button', 'Arabic')");
    await page.settle(500);
    const arabic = await page.eval(`({
      dir: $('f-greeting-ar').dir,
      value: $('f-greeting-ar').value,
      other: $('f-greeting-ar').closest('.field').querySelector('.otherLang').textContent,
    })`);
    check(
      'Arabic is edited right to left',
      arabic.dir === 'rtl',
      JSON.stringify(arabic),
    );
    check(
      'the English is still shown while Arabic is being edited',
      arabic.other.includes('Good evening'),
      arabic.other,
    );
    await page.screenshot(shot('04-profile-arabic-desktop.png'));

    await page.eval("clickText('.langTabs button', 'English')");
    await page.settle(400);
    check(
      'switching back keeps the English draft',
      (await page.eval("$('f-greeting-en').value")) === 'Good evening',
    );

    // --- validation --------------------------------------------------------
    await page.eval("setValue('f-positioning-en', '')");
    await quiet(page);
    const invalid = await page.eval(`({
      issue: (document.querySelector('#editor .issue') || {}).textContent || '',
      publish: $('publish').disabled,
      badge: $('problemCount').textContent,
    })`);
    check(
      'an empty required field is reported and blocks publishing',
      invalid.publish && invalid.issue.length > 0 && /1 problem/.test(invalid.badge),
      JSON.stringify(invalid),
    );
    await page.screenshot(shot('05-validation-desktop.png'));
    await page.eval("setValue('f-positioning-en', 'Fixture engineer.')");
    await quiet(page);
    check(
      'fixing it re-enables publishing',
      (await page.eval("$('publish').disabled")) === false,
    );

    // --- publishing --------------------------------------------------------
    // Publishing goes through the review sheet from A3 onwards: the confirmation
    // is the point, so there is no longer a button that skips it.
    await page.eval("$('publish').click()");
    await page.settle(900);
    await page.eval(
      "setValue('sourceNote', 'Fixture, for verification only')",
    );
    const published = await page.eval(`(async () => {
      [...document.querySelectorAll('#sheetBody button')]
        .find((b) => b.textContent.trim().startsWith('Publish')).click();
      await new Promise((done) => setTimeout(done, 1200));
      const listed = await fetch('/v1/admin/content', {
        headers: {authorization: 'Bearer ' + ${JSON.stringify(token)}},
      }).then((r) => r.json());
      return {
        status: $('status').textContent,
        source: $('source').textContent,
        published: listed.published,
        changes: $('changeCount').textContent,
      };
    })()`, true);
    check(
      'publishing through the review sheet stores it and clears the marker',
      published.published.includes('profile.json') &&
        /No changes/.test(published.changes),
      JSON.stringify(published),
    );

    // Read it the way the site does: cross-origin, with an Origin header the
    // browser will not let a page forge. The panel and the content share an
    // origin in this harness and would not send one at all.
    const asTheSiteSeesIt = await fetch(base + '/v1/content/profile.json', {
      headers: {origin: base},
    }).then((response) => (response.ok ? response.json() : null));
    check(
      'the site now receives the published document',
      asTheSiteSeesIt &&
        asTheSiteSeesIt.greeting.en === 'Good evening' &&
        asTheSiteSeesIt.positioning.en === 'Fixture engineer.',
      JSON.stringify(asTheSiteSeesIt && asTheSiteSeesIt.greeting),
    );

    // --- narrower windows --------------------------------------------------
    await page.viewport(1100, 820);
    const narrow = await page.eval(`({
      outline: getComputedStyle($('previewPane')).display,
      toggle: getComputedStyle($('previewToggle')).display,
      overflow: document.documentElement.scrollWidth <= window.innerWidth + 1,
    })`);
    check(
      'the third column folds behind a control when there is no room',
      narrow.outline === 'none' && narrow.toggle !== 'none' && narrow.overflow,
      JSON.stringify(narrow),
    );
    await page.screenshot(shot('06-tablet-1100.png'));

    await page.viewport(390, 844, true);
    await page.settle(400);
    const phone = await page.eval(`(() => {
      const rail = $('rail').getBoundingClientRect();
      const editor = $('editorPane').getBoundingClientRect();
      const small = [...document.querySelectorAll('#editor button, #rail button')]
        .filter((n) => n.getBoundingClientRect().height > 0)
        .filter((n) => n.getBoundingClientRect().height < 44)
        .map((n) => n.textContent.trim() || n.getAttribute('aria-label'));
      return {
        stacked: rail.bottom <= editor.top + 1,
        overflow: document.documentElement.scrollWidth <= window.innerWidth + 1,
        small: small,
      };
    })()`);
    check(
      'the phone layout is one column with nothing spilling sideways',
      phone.stacked && phone.overflow,
      JSON.stringify(phone),
    );
    check(
      'every tap target on a phone is big enough to hit',
      phone.small.length === 0,
      phone.small.join(', '),
    );
    await page.screenshot(shot('07-phone-390.png'));

    await page.eval("clickText('#rail .section', 'Journey')");
    await page.settle(500);
    await page.screenshot(shot('08-phone-journey.png'));

    // --- nothing broke quietly ---------------------------------------------
    const noisy = noise(page);
    check(
      'the browser reported no errors while all of that happened',
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
