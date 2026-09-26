/** Atomic counters for consented visits. No event log or raw identity is kept. */
const dayMs = 86400000;
const json = (body) => Response.json(body);
const hex = (bytes) => [...bytes].map((b) => b.toString(16).padStart(2, '0')).join('');
const digest = async (value) => hex(new Uint8Array(await crypto.subtle.digest(
  'SHA-256', new TextEncoder().encode(value),
)));

export class AnalyticsStore {
  constructor(state) {
    this.state = state;
    this.storage = state.storage;
  }

  async fetch(request) {
    const input = await request.json();
    return this.state.blockConcurrencyWhile(async () => {
      if (input.op === 'record') return json(await this.record(input));
      if (input.op === 'snapshot') return json(await this.snapshot(input));
      return json({error: 'Unknown operation'});
    });
  }

  async record({beacon, country, address, agent, now}) {
    const received = new Date(now);
    const date = received.toISOString().slice(0, 10);
    const hour = String(received.getUTCHours()).padStart(2, '0');
    // One salt, one UTC day, even when the first requests arrive together.
    let salt = await this.storage.get('salt');
    if (salt?.date !== date) {
      salt = {date, value: hex(crypto.getRandomValues(new Uint8Array(32)))};
      await this.storage.put('salt', salt);
    }
    // These request fields exist only in memory and are discarded here.
    const visitor = await digest(salt.value + '\0' + address + '\0' + agent);
    const dimensions = [date, beacon.event, beacon.route, country,
      beacon.deviceClass, beacon.referrerHost ?? '-', beacon.campaign ?? '-',
      beacon.target ?? '-', beacon.destination ?? '-', hour];
    const name = 'row|' + dimensions.map(encodeURIComponent).join('|');
    const visitorKey = 'visitor|' + date + '|' + visitor;
    const limitKey = 'rate|' + date + '|' + visitor;
    const minute = Math.floor(now / 60000);
    const result = await this.storage.transaction(async (txn) => {
      const rate = await txn.get(limitKey);
      if (rate?.minute === minute && rate.count >= 120) return {limited: true};
      await txn.put(limitKey, {minute, count: rate?.minute === minute ? rate.count + 1 : 1});
      const held = await txn.get(name) ?? {dimensions, count: 0, total: 0};
      held.count += 1;
      held.total += beacon.value ?? 0;
      await txn.put(name, held);
      if (beacon.event === 'route_view' && !await txn.get(visitorKey)) {
        await txn.put(visitorKey, true);
        const key = 'unique|' + date;
        await txn.put(key, (await txn.get(key) ?? 0) + 1);
      }
      const meta = await txn.get('meta') ?? {firstEventAt: now};
      await txn.put('meta', {...meta, lastEventAt: now});
      return {accepted: true};
    });
    if (await this.storage.getAlarm() === null) {
      await this.storage.setAlarm((Math.floor(now / dayMs) + 1) * dayMs);
    }
    return result;
  }

  async *rows(options) {
    let startAfter;
    for (;;) {
      const page = await this.storage.list({...options, startAfter, limit: 500});
      if (!page.size) break;
      yield* page;
      if (page.size < 500) break;
      startAfter = [...page.keys()].at(-1);
    }
  }

  async snapshot({from = '0000-00-00', to = '9999-99-99'}) {
    const counters = [], totals = [];
    for await (const [, row] of this.rows({prefix: 'row|', start: 'row|' + from, end: 'row|' + to + '~'})) {
      counters.push({dimensions: row.dimensions, count: row.count});
      if (row.total) totals.push({dimensions: row.dimensions.slice(0, 3), total: row.total});
    }
    for await (const [key, count] of this.rows({prefix: 'unique|', start: 'unique|' + from, end: 'unique|' + to + '~'})) {
      counters.push({dimensions: [key.slice(7), 'unique_visitor'], count});
    }
    return {counters, totals, metadata: await this.storage.get('meta') ?? null};
  }

  async alarm() {
    return this.state.blockConcurrencyWhile(async () => {
      const now = Date.now();
      const oldest = new Date(now);
      oldest.setUTCMonth(oldest.getUTCMonth() - 24);
      const cutoff = oldest.toISOString().slice(0, 10);
      const shortCutoff = new Date(now - dayMs).toISOString().slice(0, 10);
      for (const [prefix, before] of [['row|', cutoff], ['unique|', cutoff], ['visitor|', shortCutoff], ['rate|', shortCutoff]]) {
        for await (const [key] of this.rows({prefix, end: prefix + before})) await this.storage.delete(key);
      }
      const salt = await this.storage.get('salt');
      if (salt && salt.date < new Date(now).toISOString().slice(0, 10)) await this.storage.delete('salt');
      await this.storage.setAlarm((Math.floor(now / dayMs) + 1) * dayMs);
    });
  }
}

export async function analyticsOperation(env, input) {
  const id = env.ANALYTICS_STORE.idFromName('portfolio');
  const result = await env.ANALYTICS_STORE.get(id).fetch('https://analytics.internal/', {
    method: 'POST', body: JSON.stringify(input),
  });
  if (!result.ok) throw new Error('Analytics store is unavailable');
  return result.json();
}
