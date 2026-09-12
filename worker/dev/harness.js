/**
 * The parts every phase's browser run needs: signing in, reporting, files.
 *
 * Each phase has its own scenario script. They all start the same way and
 * they all print the same way, and three copies of that would drift.
 */

import {mkdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';

import {launch} from './browser.js';

export const base = process.env.ADMIN_BASE ?? 'http://localhost:8788';
export const token =
  process.env.ADMIN_TOKEN ?? 'local-development-token-' + 'x'.repeat(24);

/// Small conveniences installed in the page, so a scenario reads as actions
/// rather than as querySelector calls.
export const helpers = `
  window.$ = (id) => document.getElementById(id);
  window.setValue = (id, text) => {
    const node = document.getElementById(id);
    node.focus();
    node.value = text;
    node.dispatchEvent(new Event('input', {bubbles: true}));
    return true;
  };
  window.clickText = (selector, text) => {
    const node = [...document.querySelectorAll(selector)]
      .find((entry) => entry.textContent.trim().startsWith(text));
    if (!node) return false;
    node.click();
    return true;
  };
  /// Puts a real File on a real file input and lets the page's own handler
  /// take it, so an upload is exercised through the code the owner uses.
  window.attachFile = (id, bytes, name, type) => {
    const input = document.getElementById(id);
    if (!input) return false;
    const carrier = new DataTransfer();
    carrier.items.add(new File([new Uint8Array(bytes)], name, {type}));
    input.files = carrier.files;
    input.dispatchEvent(new Event('change', {bubbles: true}));
    return true;
  };
  /// A genuine RIFF/WAVE header with silence behind it.
  window.wavBytes = (seconds) => {
    const rate = 8000;
    const byteRate = rate * 2;
    const dataSize = Math.round(byteRate * seconds);
    const bytes = new Uint8Array(44 + dataSize);
    const view = new DataView(bytes.buffer);
    const ascii = (at, text) => {
      for (let i = 0; i < text.length; i += 1) bytes[at + i] = text.charCodeAt(i);
    };
    ascii(0, 'RIFF');
    view.setUint32(4, 36 + dataSize, true);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    view.setUint32(16, 16, true);
    view.setUint16(20, 1, true);
    view.setUint16(22, 1, true);
    view.setUint32(24, rate, true);
    view.setUint32(28, byteRate, true);
    view.setUint16(32, 2, true);
    view.setUint16(34, 16, true);
    ascii(36, 'data');
    view.setUint32(40, dataSize, true);
    return [...bytes];
  };
  /// A real PNG, drawn and encoded by the browser rather than faked.
  window.pngBytes = async (width, height) => {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const pen = canvas.getContext('2d');
    pen.fillStyle = '#E3A93F';
    pen.fillRect(0, 0, width, height);
    pen.fillStyle = '#121826';
    pen.fillRect(8, 8, width - 16, height - 16);
    const blob = await new Promise((done) => canvas.toBlob(done, 'image/png'));
    return [...new Uint8Array(await blob.arrayBuffer())];
  };
`;

/// Collects results and prints them as they happen.
export function reporter() {
  const results = [];
  const record = (name, passed, detail = '') => {
    results.push({name, passed, detail});
    process.stdout.write(
      (passed ? '  ok   ' : '  FAIL ') + name +
        (detail ? '  -- ' + detail : '') + '\n',
    );
  };
  return {
    results,
    check: (name, condition, detail = '') => record(name, Boolean(condition), detail),
    finish() {
      const failed = results.filter((entry) => !entry.passed);
      process.stdout.write(
        '\n' + (results.length - failed.length) + '/' + results.length +
          ' checks passed\n',
      );
      return failed.length === 0;
    },
  };
}

/// Where a scenario's captures go. `pathname` percent-encodes the space in the
/// checkout's directory name, so the URL is converted rather than read raw.
export async function captures(folder) {
  const directory = new URL('../../docs/audits/' + folder + '/', import.meta.url);
  await mkdir(directory, {recursive: true});
  return (name) => fileURLToPath(new URL(name, directory));
}

/// Opens the panel and signs in.
export async function openPanel({width = 1440, height = 900} = {}) {
  const page = await launch({width, height});
  await page.goto(base + '/admin');
  await page.eval(helpers);
  await page.eval(`setValue('token', ${JSON.stringify(token)})`);
  await page.eval("$('unlock').click()");
  await page.settle(1200);
  const open = await page.eval("$('frame').classList.contains('on')");
  if (!open) throw new Error('The panel did not accept the harness token');
  return page;
}

/// Waits until the panel has no validation in flight.
///
/// Replaces sleeping for a guessed interval. The panel marks the body while a
/// check is pending or outstanding, so this returns as soon as the answer is
/// on screen and fails loudly if it never arrives.
export async function quiet(page, timeout = 10000) {
  const started = Date.now();
  while (Date.now() - started < timeout) {
    const checking = await page.eval(
      "document.body.dataset.checking === '1'",
    );
    if (!checking) {
      await page.settle(60);
      return;
    }
    await page.settle(60);
  }
  throw new Error('The panel never finished checking the draft');
}

/// Anything the browser complained about while the scenario ran.
export function noise(page) {
  return page.logs.filter(
    (entry) => entry.level === 'error' || entry.level === 'exception',
  );
}
