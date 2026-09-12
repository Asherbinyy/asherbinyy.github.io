/**
 * Phase A4 in a browser: sessions, signing out, the password, and what
 * happens when a session ends while there is unpublished work on screen.
 *
 *   node worker/dev/serve.js 8788 &
 *   npm exec --yes --package=node@22 -- node worker/dev/verify-a4.js
 */

import {base, captures, noise, openPanel, quiet, reporter, token} from './harness.js';

const {check, finish} = reporter();
const password = 'a-long-enough-fixture-password';

async function main() {
  const shot = await captures('2026-09-12-admin-a4');
  const page = await openPanel();

  try {
    // The panel opens on Home from A6 onwards; these checks are about the
    // editing side of it.
    await page.eval("clickText('#rail .section', 'Profile')");
    await page.settle(500);

    // --- what the browser is actually holding -----------------------------
    const held = await page.eval(
      "sessionStorage.getItem('portfolio.admin.session')",
    );
    check(
      'the browser keeps a session, not the credential that rewrites the site',
      typeof held === 'string' && held.length === 64 && held !== token,
      String(held).slice(0, 12) + '...',
    );

    await page.eval("clickText('#rail .section', 'Account')");
    await page.settle(900);
    const account = await page.eval("$('editor').innerText");
    check(
      'the account section says how you got in and when it ends',
      /Signed in with a session/.test(account) && /twelve hours/.test(account),
      account.slice(0, 100),
    );
    check(
      'it says no password is set yet',
      /No password is set yet/.test(account),
    );
    check(
      'it states that no hosting credential reaches this page',
      /never receives a Cloudflare account credential/.test(account),
    );
    await page.screenshot(shot('01-account.png'));

    // --- a session ending mid-edit ----------------------------------------
    await page.eval("clickText('#rail .section', 'Profile')");
    await quiet(page);
    await page.eval("setValue('f-greeting-en', 'Work in progress')");
    await quiet(page);

    // End the session out from under the panel, the way twelve hours would.
    await fetch(`${base}/v1/admin/session`, {
      method: 'DELETE',
      headers: {authorization: `Bearer ${held}`},
    });

    await page.eval("$('history').click()");
    await page.settle(900);
    const stranded = await page.eval(`({
      asking: $('reauth').open,
      draft: $('f-greeting-en').value,
      changes: $('changeCount').textContent,
    })`);
    check(
      'a session that ends mid-edit asks for the password again',
      stranded.asking,
      JSON.stringify(stranded),
    );
    check(
      'and the unpublished draft is still there behind it',
      stranded.draft === 'Work in progress' && /1 change/.test(stranded.changes),
      JSON.stringify(stranded),
    );
    await page.screenshot(shot('02-session-ended.png'));

    await page.eval(`setValue('reauthPassword', 'wrong password')`);
    await page.eval("$('reauthGo').click()");
    await page.settle(800);
    check(
      'a wrong password there says so and keeps asking',
      await page.eval(
        "$('reauth').open && $('reauthError').textContent.length > 0",
      ),
      await page.eval("$('reauthError').textContent"),
    );

    await page.eval(`setValue('reauthPassword', ${JSON.stringify(token)})`);
    await page.eval("$('reauthGo').click()");
    await page.settle(1200);
    const back = await page.eval(`({
      closed: $('reauth').open === false,
      draft: $('f-greeting-en').value,
      status: $('status').textContent,
    })`);
    check(
      'signing back in carries on exactly where it was',
      back.closed && back.draft === 'Work in progress',
      JSON.stringify(back),
    );

    // --- setting a password -----------------------------------------------
    await page.eval("clickText('#rail .section', 'Account')");
    await page.settle(900);
    await page.eval("setValue('newPassword', 'short')");
    await page.eval("setValue('currentPassword', " + JSON.stringify(token) + ")");
    await page.eval("clickText('#editor .group button', 'Set it')");
    await page.settle(600);
    check(
      'a password that is too short is refused before it is sent',
      await page.eval(
        "/twelve characters/.test($('editor').innerText)",
      ),
    );

    await page.eval(`setValue('newPassword', ${JSON.stringify(password)})`);
    await page.eval("clickText('#editor .group button', 'Set it')");
    await page.settle(1500);
    const set = await page.eval(`({
      status: $('status').textContent,
      body: $('editor').innerText,
      session: sessionStorage.getItem('portfolio.admin.session'),
    })`);
    check(
      'setting a password works and says the other sessions are gone',
      /Password changed/.test(set.status) &&
        /every other session/i.test(set.status),
      set.status,
    );
    check(
      'the panel is handed a new session rather than being signed out',
      typeof set.session === 'string' && set.session.length === 64 &&
        set.session !== held,
    );
    check(
      'the account section now says a password is set',
      /A password is set/.test(set.body),
      set.body.slice(0, 120),
    );
    await page.screenshot(shot('03-password-set.png'));

    // The old session really is dead.
    const oldOne = await fetch(`${base}/v1/admin/content`, {
      headers: {authorization: `Bearer ${held}`},
    });
    check('the session it replaced no longer works', oldOne.status === 401);

    // And the new password gets in on its own.
    const withPassword = await fetch(`${base}/v1/admin/session`, {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({password}),
    });
    check('the new password signs in on its own', withPassword.status === 200);

    // --- being guessed at does not lock the owner out ---------------------
    for (let attempt = 0; attempt < 15; attempt += 1) {
      await fetch(`${base}/v1/admin/session`, {
        method: 'POST',
        headers: {'content-type': 'application/json'},
        body: JSON.stringify({password: 'guess ' + attempt}),
      });
    }
    const stillIn = await fetch(`${base}/v1/admin/session`, {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({password}),
    });
    check(
      'fifteen wrong guesses do not lock the owner out of his own site',
      stillIn.status === 200,
      String(stillIn.status),
    );

    // --- signing out -------------------------------------------------------
    await page.eval('window.confirm = () => true');
    // Signing out reloads the page, so the click has to be waited on as a
    // navigation rather than as an ordinary evaluation.
    await page.navigateBy("clickText('#editor .group button', 'Sign out')");
    const out = await page.eval(`({
      gate: $('gate').hidden === false,
      frame: $('frame').classList.contains('on'),
      stored: sessionStorage.getItem('portfolio.admin.session'),
    })`);
    check(
      'signing out returns to the gate and keeps nothing',
      out.gate && !out.frame && out.stored === null,
      JSON.stringify(out),
    );
    await page.screenshot(shot('04-signed-out.png'));

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
