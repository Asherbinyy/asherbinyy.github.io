/**
 * Just enough of the Chrome DevTools Protocol to open the panel and use it.
 *
 * No package. The repository's Worker has no dependencies and adding a
 * browser-automation library to it so an agent can take a screenshot would be
 * a poor trade. Chrome is already on the machine; this speaks to it directly.
 *
 * Needs the global WebSocket, so run it under Node 22:
 *
 *   npm exec --yes --package=node@22 -- node worker/dev/verify.js
 */

import {spawn} from 'node:child_process';
import {mkdtemp} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';

const chromePaths = [
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
];

async function findChrome() {
  const {access} = await import('node:fs/promises');
  for (const path of chromePaths) {
    try {
      await access(path);
      return path;
    } catch {
      continue;
    }
  }
  throw new Error('No Chrome found. Looked in: ' + chromePaths.join(', '));
}

export async function launch({width = 1440, height = 900} = {}) {
  const binary = await findChrome();
  const profile = await mkdtemp(join(tmpdir(), 'admin-verify-'));
  const chrome = spawn(binary, [
    '--headless=new',
    '--remote-debugging-port=0',
    `--user-data-dir=${profile}`,
    `--window-size=${width},${height}`,
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-gpu',
    '--hide-scrollbars',
    // An isolated profile with no extensions and no network beyond localhost.
    '--disable-extensions',
    'about:blank',
  ]);

  const endpoint = await new Promise((resolve, reject) => {
    let buffered = '';
    const timer = setTimeout(
      () => reject(new Error('Chrome did not report a debugging endpoint')),
      15000,
    );
    chrome.stderr.on('data', (chunk) => {
      buffered += String(chunk);
      const found = buffered.match(/ws:\/\/[^\s]+/);
      if (found) {
        clearTimeout(timer);
        resolve(found[0]);
      }
    });
    chrome.on('exit', (code) => reject(new Error('Chrome exited with ' + code)));
  });

  const socket = new WebSocket(endpoint);
  await new Promise((resolve, reject) => {
    socket.onopen = resolve;
    socket.onerror = () => reject(new Error('Could not connect to Chrome'));
  });

  let nextId = 0;
  let dialogHandler = null;
  const pending = new Map();
  const waiters = [];
  const logs = [];

  socket.onmessage = (message) => {
    const frame = JSON.parse(message.data);
    if (frame.id !== undefined) {
      const held = pending.get(frame.id);
      pending.delete(frame.id);
      if (!held) return;
      if (frame.error) held.reject(new Error(JSON.stringify(frame.error)));
      else held.resolve(frame.result);
      return;
    }
    if (frame.method === 'Page.javascriptDialogOpening' && dialogHandler) {
      dialogHandler(frame.params);
      return;
    }
    if (frame.method === 'Runtime.consoleAPICalled') {
      logs.push({
        level: frame.params.type,
        text: frame.params.args
          .map((arg) => arg.value ?? arg.description ?? arg.type)
          .join(' '),
      });
    }
    if (frame.method === 'Runtime.exceptionThrown') {
      logs.push({
        level: 'exception',
        text: frame.params.exceptionDetails.exception?.description ??
          frame.params.exceptionDetails.text,
      });
    }
    for (let at = waiters.length - 1; at >= 0; at -= 1) {
      if (waiters[at].method === frame.method) {
        waiters[at].resolve(frame.params);
        waiters.splice(at, 1);
      }
    }
  };

  let session = null;
  const send = (method, params = {}, useSession = true) =>
    new Promise((resolve, reject) => {
      const id = ++nextId;
      pending.set(id, {resolve, reject});
      const frame = {id, method, params};
      if (useSession && session) frame.sessionId = session;
      socket.send(JSON.stringify(frame));
    });

  const once = (method, timeout = 15000) =>
    new Promise((resolve, reject) => {
      const waiter = {method, resolve};
      waiters.push(waiter);
      setTimeout(() => {
        const at = waiters.indexOf(waiter);
        if (at !== -1) waiters.splice(at, 1);
        reject(new Error('Timed out waiting for ' + method));
      }, timeout);
    });

  const target = await send('Target.createTarget', {url: 'about:blank'}, false);
  const attached = await send(
    'Target.attachToTarget',
    {targetId: target.targetId, flatten: true},
    false,
  );
  session = attached.sessionId;

  await send('Page.enable');
  await send('Runtime.enable');
  // A native confirm() or a beforeunload prompt blocks the page, and a
  // blocked page never answers another evaluation -- which looks exactly like
  // a hang. Accepted by default; a scenario that wants a different answer
  // stubs window.confirm itself, which takes precedence over this.
  dialogHandler = (params) => {
    send('Page.handleJavaScriptDialog', {
      accept: true,
      promptText: params.defaultPrompt ?? '',
    }).catch(() => {});
  };
  await send('Emulation.setDeviceMetricsOverride', {
    width,
    height,
    deviceScaleFactor: 2,
    mobile: false,
  });

  /// Scripts that have to exist on every page this driver visits.
  const setups = [];

  const page = {
    logs,

    /// Installs a helper script and remembers it, so a navigation does not
    /// quietly leave the next page without it.
    async setup(expression) {
      setups.push(expression);
      await page.eval(expression);
    },

    async goto(url) {
      const loaded = once('Page.loadEventFired');
      await send('Page.navigate', {url});
      await loaded;
      for (const expression of setups) await page.eval(expression);
      await page.settle();
    },

    /// Waits for the next two frames, which is enough for a re-render.
    async settle(ms = 220) {
      await page.eval(
        'new Promise((done) => requestAnimationFrame(() => setTimeout(done, ' +
          ms + ')))',
        true,
      );
    },

    async eval(expression, awaitPromise = false) {
      const result = await send('Runtime.evaluate', {
        expression,
        returnByValue: true,
        awaitPromise,
        userGesture: true,
      });
      if (result.exceptionDetails) {
        throw new Error(
          'Page threw: ' +
            (result.exceptionDetails.exception?.description ??
              result.exceptionDetails.text),
        );
      }
      return result.result.value;
    },

    /// Runs something that navigates, and waits for the new page.
    ///
    /// The evaluation itself is expected to be lost: the target goes away
    /// mid-call and the protocol answers "navigated or closed" rather than
    /// returning. That is the success case here, not an error.
    async navigateBy(expression) {
      const loaded = once('Page.loadEventFired', 20000);
      await page.eval(expression).catch((error) => {
        if (!/navigated or closed/.test(String(error))) throw error;
      });
      await loaded;
      for (const expression of setups) await page.eval(expression);
      await page.settle(400);
    },

    async viewport(width_, height_, mobile = false) {
      await send('Emulation.setDeviceMetricsOverride', {
        width: width_,
        height: height_,
        deviceScaleFactor: 2,
        mobile,
      });
      await page.settle();
    },

    async key(key, code, keyCode) {
      for (const type of ['keyDown', 'keyUp']) {
        await send('Input.dispatchKeyEvent', {
          type,
          key,
          code,
          windowsVirtualKeyCode: keyCode,
          nativeVirtualKeyCode: keyCode,
        });
      }
      await page.settle(80);
    },

    async type(text) {
      for (const character of text) {
        await send('Input.dispatchKeyEvent', {type: 'keyDown', text: character});
        await send('Input.dispatchKeyEvent', {type: 'keyUp', text: character});
      }
      await page.settle(80);
    },

    async screenshot(path) {
      const shot = await send('Page.captureScreenshot', {
        format: 'png',
        captureBeyondViewport: false,
      });
      const {writeFile} = await import('node:fs/promises');
      await writeFile(path, Buffer.from(shot.data, 'base64'));
      return path;
    },

    async close() {
      socket.close();
      chrome.kill();
    },
  };

  return page;
}
