/**
 * A Durable Object, as the runtime provides one, for tests and the harness.
 *
 * Faithful in the three ways that matter to `worker/src/store.js`:
 *
 * - `blockConcurrencyWhile` serialises, which is the guarantee the whole
 *   concurrency fix rests on.
 * - `transaction` discards everything it wrote if the body throws.
 * - a write can be made to fail on demand, so that rollback can be observed
 *   rather than assumed.
 *
 * Not a substitute for running against the real thing before deployment. It is
 * how the Worker's own logic is exercised without one.
 */

export class FakeStorage {
  map = new Map();
  failOn = null;

  async get(key) {
    return this.map.has(key) ? structuredClone(this.map.get(key)) : undefined;
  }

  async put(key, value) {
    if (this.failOn === key) throw new Error('injected storage failure');
    this.map.set(key, structuredClone(value));
  }

  async delete(key) {
    this.map.delete(key);
  }

  async list({prefix = ''} = {}) {
    return new Map(
      [...this.map.entries()]
        .filter(([key]) => key.startsWith(prefix))
        .sort(([left], [right]) => (left < right ? -1 : 1))
        .map(([key, value]) => [key, structuredClone(value)]),
    );
  }

  async transaction(body) {
    const before = new Map(this.map);
    try {
      return await body(this);
    } catch (error) {
      this.map = before;
      throw error;
    }
  }
}

export class FakeState {
  storage = new FakeStorage();
  queue = Promise.resolve();

  blockConcurrencyWhile(body) {
    const running = this.queue.then(() => body());
    this.queue = running.then(
      () => undefined,
      () => undefined,
    );
    return running;
  }
}

/// A namespace binding holding exactly one object, which is how the Worker
/// uses it.
export function durableNamespace(ContentStore) {
  const state = new FakeState();
  const object = new ContentStore(state);
  return {
    state,
    idFromName: (name) => name,
    get: () => ({
      fetch: (url, init) => object.fetch(new Request(url, init)),
    }),
  };
}
