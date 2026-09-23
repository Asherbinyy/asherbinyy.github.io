/**
 * Phase A6 in a browser: the home dashboard, and what it refuses to say.
 *
 *   node worker/dev/serve.js 8788 &
 *   npm exec --yes --package=node@22 -- node worker/dev/verify-a6.js
 */

import {base, captures, noise, openPanel, reporter, token} from './harness.js';

const {check, finish} = reporter();

/// Puts counters straight into the store, the way a consented session would
/// have. Nothing here turns collection on; it writes rows the dashboard then
/// reads back.
async function seed(rows) {
  for (const [key, value] of rows) {
    await fetch(`${base}/__seed`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({key, value}),
    });
  }
}

const today = new Date().toISOString().slice(0, 10);
const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);

async function main() {
  const shot = await captures('2026-09-12-admin-a6');
  const page = await openPanel();

  try {
    // --- the empty state --------------------------------------------------
    check(
      'the panel opens on the dashboard',
      (await page.eval(
        "$('rail').querySelector('[aria-current=page]').textContent",
      )) === 'Home',
      await page.eval("document.querySelector('#editor h2').textContent"),
    );
    await page.settle(900);
    const empty = await page.eval("$('editor').innerText");
    check(
      'an empty dashboard says nothing has been recorded',
      /Nothing has ever been recorded here/.test(empty),
      empty.slice(0, 120),
    );
    check(
      'and says that is because nothing is being counted, not that nobody came',
      /does not mean\s+nobody came/.test(empty) &&
        /built without an analytics endpoint/.test(empty),
    );
    check(
      'it does not show a grid of zeros',
      !/\b0\s+page views/i.test(empty),
      empty.slice(0, 200),
    );
    check(
      'publishing controls are inert on the dashboard',
      await page.eval(
        "['publish', 'discard', 'history', 'withdraw'].every((id) => $(id).disabled)",
      ),
    );
    await page.screenshot(shot('01-empty.png'));

    // --- with data --------------------------------------------------------
    await seed([
      [`counter|${today}|route_view|%2F|GB|desktop|-|-`, '18'],
      [`counter|${today}|route_view|%2Fwork|GB|desktop|medium.com|-`, '11'],
      [`counter|${today}|route_view|%2Fwork|EG|phone|-|-`, '6'],
      [`counter|${yesterday}|route_view|%2Fabout|EG|phone|-|-`, '4'],
      [`counter|${today}|cv_opened|%2Fabout|GB|desktop|-|-`, '3'],
      [`counter|${today}|section_dwell|%2Fwork|GB|desktop|-|-`, '4'],
      [`counter|${today}|unique_visitor`, '7'],
      [`counter|${yesterday}|unique_visitor`, '5'],
      [`total|${today}|section_dwell|%2Fwork`, '240'],
    ]);
    await page.eval("clickText('#rail .section', 'Home')");
    await page.settle(1400);
    const seen = await page.eval("$('editor').innerText");
    const figures = await page.eval(
      "[...document.querySelectorAll('.figure')].map((f) => f.innerText.replace(/\\n/g, ' | '))",
    );
    check(
      'views and interactions are counted separately',
      figures.some((text) => /^39 \| PAGE VIEWS/.test(text)) &&
        figures.some((text) => /^7 \| INTERACTIONS/.test(text)),
      figures.join('  //  '),
    );
    // Seven and five on two days. The sum, twelve, is the number that must not
    // appear as a figure: it would be counting the returning visitors twice.
    const values = await page.eval(
      "[...document.querySelectorAll('.figure strong')].map((n) => n.textContent)",
    );
    check(
      'the multi-day unique figure is the busiest day, not a sum',
      figures.some((text) => /^7 \| BUSIEST DAY/.test(text)) &&
        !values.includes('12'),
      values.join(', '),
    );
    check(
      'and it says why there is no visitor total',
      /Why there is no visitor total/.test(seen) && /salt/.test(seen),
    );

    const routes = await page.eval(`(() => {
      const group = [...document.querySelectorAll('.group')]
        .find((g) => /Pages viewed/.test(g.querySelector('h3').textContent));
      return [...group.querySelectorAll('.bar')].map((b) => b.innerText.replace(/\\n/g, ' '));
    })()`);
    check(
      'pages are broken down by real route and ordered by size',
      /^\/ .*18$/.test(routes[0].trim()) && /^\/work .*17$/.test(routes[1].trim()),
      routes.join(' | '),
    );
    check(
      'a unique-visitor row never appears as an event or a route',
      !/unique_visitor/.test(seen),
    );
    check(
      'an average says what its unit is',
      /section_dwell on \/work: 60 seconds, over 4 events/.test(seen),
      (seen.match(/section_dwell on[^\n]*/) || [''])[0],
    );
    check(
      'a referrer that was never recorded is not shown as a dash',
      /medium\.com/.test(seen) && !/^-$/m.test(seen),
    );
    check(
      'retention is stated rather than left for the owner to wonder about',
      /24 calendar months/.test(seen) && /2 days/.test(seen),
    );
    await page.screenshot(shot('02-with-data.png'));

    // --- ranges -----------------------------------------------------------
    await page.eval("clickText('#editor .checks button', 'Last 7 days')");
    await page.settle(1200);
    check(
      'the range can be changed and says which days it covers, in UTC',
      /in UTC/.test(await page.eval("$('editor').innerText")),
    );

    await page.eval("clickText('#editor .checks button', 'Choose dates')");
    await page.settle(900);
    check(
      'a custom range offers two dates',
      await page.eval("Boolean($('range-from') && $('range-to'))"),
    );
    await page.eval("setValue('range-from', '2020-01-01')");
    await page.eval(
      "$('range-from').dispatchEvent(new Event('change', {bubbles: true}))",
    );
    await page.settle(300);
    await page.eval("setValue('range-to', '2020-01-31')");
    await page.eval(
      "$('range-to').dispatchEvent(new Event('change', {bubbles: true}))",
    );
    await page.settle(1400);
    const past = await page.eval("$('editor').innerText");
    check(
      'a range with nothing in it says so, and says data exists outside it',
      /Nothing in this range/.test(past) && /There is data outside it/.test(past),
      past.slice(0, 200),
    );
    await page.screenshot(shot('03-empty-range.png'));

    // --- phone ------------------------------------------------------------
    await page.eval("clickText('#editor .checks button', 'Last 28 days')");
    await page.settle(1200);
    await page.viewport(390, 844, true);
    await page.settle(700);
    check(
      'the dashboard fits a phone',
      await page.eval(
        'document.documentElement.scrollWidth <= window.innerWidth + 1',
      ),
    );
    await page.screenshot(shot('04-phone.png'));

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
