/**
 * Phase A2 in a browser: the media library and the controls that use it.
 *
 *   node worker/dev/serve.js 8788 &
 *   npm exec --yes --package=node@22 -- node worker/dev/verify-a2.js
 */

import {captures, noise, openPanel, quiet, reporter} from './harness.js';

const {check, finish} = reporter();

async function main() {
  const shot = await captures('2026-09-12-admin-a2');
  const page = await openPanel();

  try {
    // The panel opens on Home from A6 onwards; these checks are about the
    // editing side of it.
    await page.eval("clickText('#rail .section', 'Profile')");
    await page.settle(500);

    // --- the library is a place you can get to ----------------------------
    check(
      'the library is a section of its own',
      await page.eval("clickText('#rail .section', 'Media')"),
    );
    await page.settle(700);
    check(
      'an empty library says so rather than showing an empty grid',
      /Nothing uploaded yet/.test(await page.eval("$('editor').innerText")),
    );
    check(
      'publishing controls are inert on a section that is not a page',
      await page.eval(
        "['publish', 'discard', 'history', 'withdraw']" +
          ".every((id) => $(id).disabled)",
      ),
    );

    // --- uploading a picture ----------------------------------------------
    await page.eval(
      "pngBytes(240, 180).then((b) => attachFile('upload-image', b, 'shot.png', 'image/png'))",
      true,
    );
    await page.settle(1200);
    const stored = await page.eval(`(() => {
      const cards = [...document.querySelectorAll('.mediaCard')];
      return {
        cards: cards.length,
        description: cards.length ? cards[0].querySelector('h3').textContent : '',
        reference: cards.length ? cards[0].querySelector('.mono').textContent : '',
        unused: /Nothing is using this/.test($('editor').innerText),
      };
    })()`);
    check(
      'an uploaded picture is listed with its real dimensions and size',
      stored.cards === 1 && /240 by 180/.test(stored.description),
      JSON.stringify(stored),
    );
    check(
      'a stored file is addressed by a fingerprint of its contents',
      /^\/v1\/media\/[0-9a-f]{32}$/.test(stored.reference),
      stored.reference,
    );
    check('a file nothing points at says so', stored.unused);

    // --- uploading a recording --------------------------------------------
    await page.eval(
      "attachFile('upload-audio', wavBytes(1.5), 'name.wav', 'audio/wav')",
    );
    await page.settle(1200);
    const sound = await page.eval(`(() => {
      const cards = [...document.querySelectorAll('.mediaCard')];
      const descriptions = cards.map((c) => c.querySelector('h3').textContent);
      return {
        cards: cards.length,
        descriptions: descriptions,
        players: document.querySelectorAll('.mediaCard audio').length,
      };
    })()`);
    check(
      'a recording is stored with the length read from its own header',
      sound.cards === 2 && sound.descriptions.some((text) => /1\.5s/.test(text)),
      JSON.stringify(sound.descriptions),
    );
    check('a recording is listed with something to play it on', sound.players === 1);
    await page.screenshot(shot('01-library-desktop.png'));

    // --- refusing what it should refuse -----------------------------------
    await page.eval(`attachFile('upload-image', [...new TextEncoder()
      .encode('<script>alert(1)</script>')], 'bad.png', 'image/png')`);
    await page.settle(900);
    const refused = await page.eval(`(() => {
      const row = $('upload-image').closest('.field');
      const retry = [...row.querySelectorAll('button')]
        .find((b) => b.textContent.trim() === 'Try again');
      return {
        message: row.querySelector('.help:not(:first-of-type)')
          ? row.innerText : row.innerText,
        retryOffered: Boolean(retry) && !retry.hidden,
        cards: document.querySelectorAll('.mediaCard').length,
      };
    })()`);
    check(
      'a file that is not really a picture is refused and nothing is stored',
      refused.cards === 2 && /not a readable image/i.test(refused.message),
      JSON.stringify(refused).slice(0, 200),
    );
    check('a failed upload offers to try again', refused.retryOffered);
    await page.screenshot(shot('02-upload-refused.png'));

    // --- using a stored file in a field -----------------------------------
    await page.eval("clickText('#rail .section', 'Profile')");
    await page.settle(600);
    const controls = await page.eval(`(() => {
      const field = $('f-portrait-src').closest('.field');
      return {
        buttons: [...field.querySelectorAll('button, label.buttonish')]
          .map((n) => n.textContent.trim()),
      };
    })()`);
    check(
      'an image field can upload, reuse or clear',
      ['Upload', 'Choose from library', 'Clear'].every((name) =>
        controls.buttons.includes(name)),
      controls.buttons.join(' | '),
    );

    await page.eval(
      "clickText('#f-portrait-src ~ .listFoot button, .listFoot button', 'Choose from library')",
    );
    await page.settle(900);
    check(
      'the library offers only what the field can hold',
      await page.eval(`(() => {
        const choices = [...document.querySelectorAll('.mediaChoice')];
        return choices.length === 1 && choices[0].querySelector('img') !== null;
      })()`),
    );
    await page.screenshot(shot('03-picker.png'));
    await page.eval("document.querySelector('.mediaChoice').click()");
    await quiet(page);
    const chosen = await page.eval("$('f-portrait-src').value");
    check(
      'choosing from the library fills the field',
      /^\/v1\/media\/[0-9a-f]{32}$/.test(chosen),
      chosen,
    );
    check(
      'the field shows what is now in it',
      await page.eval(
        "Boolean($('f-portrait-src').closest('.field').querySelector('.assetPreview img'))",
      ),
    );
    await page.eval(
      "$('f-portrait-src').closest('.field').scrollIntoView({block: 'center'})",
    );
    await page.settle(300);
    await page.screenshot(shot('04-field-with-media.png'));

    // --- the library knows who is using what ------------------------------
    await page.eval("clickText('#rail .section', 'Media')");
    await page.settle(800);
    check(
      'the library says which page is using a file',
      /Used by Profile → portrait\.src/.test(
        await page.eval("$('editor').innerText"),
      ),
      (await page.eval("$('editor').innerText")).slice(0, 160),
    );

    const guarded = await page.eval(`(() => {
      let asked = '';
      window.confirm = (text) => { asked = text; return false; };
      const card = [...document.querySelectorAll('.mediaCard')]
        .find((c) => /Used by/.test(c.innerText));
      [...card.querySelectorAll('button')]
        .find((b) => b.textContent.trim() === 'Delete').click();
      return asked;
    })()`);
    check(
      'deleting a file still in use warns and names where',
      /used by/i.test(guarded) && /portrait\.src/.test(guarded),
      guarded.slice(0, 140),
    );
    await page.settle(500);
    check(
      'declining that warning deletes nothing',
      (await page.eval('document.querySelectorAll(".mediaCard").length')) === 2,
    );

    const freeToGo = await page.eval(`(() => {
      let asked = '';
      window.confirm = (text) => { asked = text; return true; };
      const card = [...document.querySelectorAll('.mediaCard')]
        .find((c) => /Nothing is using this/.test(c.innerText));
      [...card.querySelectorAll('button')]
        .find((b) => b.textContent.trim() === 'Delete').click();
      return asked;
    })()`);
    await page.settle(1000);
    check(
      'a file nothing points at deletes without a use warning',
      !/used by/i.test(freeToGo) &&
        (await page.eval('document.querySelectorAll(".mediaCard").length')) === 1,
      freeToGo.slice(0, 100),
    );

    // --- phone ------------------------------------------------------------
    await page.viewport(390, 844, true);
    await page.settle(600);
    const phone = await page.eval(`(() => {
      // Only what is actually on screen: a control the page is deliberately
      // hiding measures zero and is not a tap target.
      const small = [...document.querySelectorAll(
        '#editor button, #editor label.buttonish')]
        .filter((n) => n.getBoundingClientRect().height > 0)
        .filter((n) => n.getBoundingClientRect().height < 44)
        .map((n) => n.textContent.trim());
      return {
        overflow: document.documentElement.scrollWidth <= window.innerWidth + 1,
        small: small,
      };
    })()`);
    check(
      'the library fits a phone with nothing spilling sideways',
      phone.overflow,
      JSON.stringify(phone),
    );
    check(
      'its controls are still big enough to tap',
      phone.small.length === 0,
      phone.small.join(', '),
    );
    await page.screenshot(shot('05-library-phone.png'));

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
