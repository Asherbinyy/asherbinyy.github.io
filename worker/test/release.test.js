import assert from 'node:assert/strict';
import test from 'node:test';
import worker, {handleRequest} from '../src/index.js';
import {readToken} from '../src/game/leaderboard.js';

const origin = 'https://sherbini.uk';

function request(path, body) {
  return new Request(`https://worker.example${path}`, {
    method: body ? 'POST' : 'GET',
    headers: {origin, 'content-type': 'application/json'},
    ...(body ? {body: JSON.stringify(body)} : {}),
  });
}

for (const clock of ['production default', 'explicit Date']) {
  test(`a challenge can be submitted with the ${clock} clock`, async () => {
    let submittedAt;
    const env = {
      SITE_ORIGIN: origin,
      SITE_ID: 'asherbinyy.github.io',
      ANALYTICS: {},
      GAME_SECRET: crypto.randomUUID(),
      GAME_BOARD: {},
      GAME_VERIFIER: {
        idFromName: (id) => id,
        get: () => ({
          async fetch(url, init) {
            submittedAt = JSON.parse(init.body).now;
            return Response.json({status: 'pending'});
          },
        }),
      },
    };
    const before = Date.now();
    const send = (req) => clock === 'production default'
      ? worker.fetch(req, env)
      : handleRequest(req, env, new Date(before));
    const playerKey = crypto.randomUUID().replaceAll('-', '');
    const start = await send(request('/v1/game/runs', {playerKey}));
    assert.equal(start.status, 200);
    const challenge = await start.json();
    assert.equal(typeof challenge.expiresAt, 'number');
    assert.ok(challenge.expiresAt > before);
    assert.ok(await readToken(env.GAME_SECRET, challenge.token, before));

    const submission = await send(request('/v1/game/leaderboard', {
      playerKey,
      token: challenge.token,
      nickname: 'Release check',
      tape: 'CA',
    }));
    assert.equal(submission.status, 202);
    assert.equal((await submission.json()).status, 'pending');
    assert.equal(typeof submittedAt, 'number');
    assert.ok(submittedAt >= before && submittedAt <= Date.now());
  });
}

test('admin bundled content uses the origin permitted by its CSP', async () => {
  const response = await worker.fetch(request('/admin'), {
    SITE_ORIGIN: origin, SITE_ID: 'asherbinyy.github.io', ANALYTICS: {},
  });
  const html = await response.text();
  assert.ok(html.includes(`const BUNDLE = "${origin}/assets/assets/content";`));
  assert.ok(response.headers.get('content-security-policy')
    .includes(`connect-src 'self' ${origin}`));
});
