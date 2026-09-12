/**
 * Where content mutations are serialised.
 *
 * The defect this exists for (AR-1): publishing read the head revision, decided
 * the base matched, and then wrote the document, the revision record and the
 * new head as three separate KV operations. Two publishes arriving together
 * both read revision 0, both decided they were current, and both returned
 * "revision 1". One of them was simply gone, along with its history entry.
 *
 * Workers KV cannot fix this. It has no compare-and-set and no transaction:
 * <https://developers.cloudflare.com/kv/concepts/how-kv-works/>. A mutex in the
 * Worker cannot fix it either, because there is no single Worker -- requests
 * land in whichever isolate the edge picked, and two isolates share nothing.
 *
 * A Durable Object can. There is exactly one instance of a given object across
 * the whole network, its execution is serialised, and its storage is strongly
 * consistent with real transactions. So all five documents are owned by one
 * object, every mutation goes through it, and the read-check-write happens
 * inside `blockConcurrencyWhile` with the commit inside `storage.transaction`.
 *
 * ## Before this is deployed
 *
 * The binding and migration are written out, commented, in `wrangler.toml`.
 * They are deliberately not enabled: turning them on is a migration of the
 * owner's live content and is his decision, not a side effect of a bug fix.
 *
 * Two things to confirm against Cloudflare's current terms before enabling
 * them, because they change and this file should not pretend to know:
 *
 * 1. **Plan availability.** Durable Objects backed by SQLite storage are the
 *    intended class here (`new_sqlite_classes` in the migration). Check that
 *    the account's plan includes them.
 * 2. **Cost.** Every public content read becomes a request to the object
 *    rather than a KV read. This site serves five documents per cold visit and
 *    very little traffic, so the expected volume is small -- but it is a
 *    different meter, and worth looking at before it is switched on.
 *
 * Until the binding exists the Worker keeps using KV exactly as it does today,
 * `atomic` is false, and the panel says so rather than implying a protection
 * it does not have. Nothing about the public response shape changes either
 * way.
 */

const documentKey = (file) => `doc:${file}`;
const headKey = (file) => `head:${file}`;
const revisionKey = (file, revision) =>
  `rev:${file}:${String(revision).padStart(6, '0')}`;
const attemptKey = (scope) => `attempt:${scope}`;

/// How long a failed-attempt counter is kept, in milliseconds.
const attemptWindowMs = 60 * 60 * 1000;

/// The single object that owns every content mutation.
///
/// One instance for all five documents rather than one per document: the
/// volume is tiny, and a snapshot is only coherent if nothing moved underneath
/// it while it was being assembled.
export class ContentStore {
  constructor(state) {
    this.state = state;
    this.storage = state.storage;
  }

  async fetch(request) {
    const asked = await request.json();
    // Serialised against every other request to this object. The
    // read-check-write below is therefore indivisible, which is the entire
    // point of routing mutations here.
    return this.state.blockConcurrencyWhile(async () => {
      switch (asked.op) {
        case 'read':
          return json(await this.storage.get(documentKey(asked.file)) ?? null);
        case 'head':
          return json(await this.storage.get(headKey(asked.file)) ?? null);
        case 'revisions':
          return json(await this.listRevisions(asked.file));
        case 'commit':
          return json(await this.commit(asked));
        case 'attempts':
          return json(await this.attempts(asked));
        default:
          return json({error: 'Unknown operation'});
      }
    });
  }

  async listRevisions(file) {
    const held = await this.storage.list({prefix: `rev:${file}:`});
    return [...held.values()];
  }

  /// Applies one mutation, or refuses it.
  ///
  /// The head is read here, inside the serialised section, rather than being
  /// trusted from the caller. Everything the mutation touches is written in
  /// one transaction, so a failure part-way leaves the document, its history
  /// and the head as they were rather than disagreeing with each other.
  async commit({file, kind, document, note, claims, base, at}) {
    const head = (await this.storage.get(headKey(file))) ?? null;
    const current = head?.revision ?? 0;

    if (base !== null && base !== undefined && base !== current) {
      return {
        conflict: true,
        expected: base,
        current,
        document: (await this.storage.get(documentKey(file))) ?? null,
        changedAt: head?.at ?? null,
      };
    }

    const revision = current + 1;
    const record = {
      revision,
      file,
      at,
      note: note ?? '',
      claims: claims ?? [],
      withdrawal: kind === 'withdraw',
    };
    if (kind !== 'withdraw') record.document = document;
    if (kind === 'rollback') record.restoredFrom = base ?? null;

    await this.storage.transaction(async (txn) => {
      if (kind === 'withdraw') await txn.delete(documentKey(file));
      else await txn.put(documentKey(file), document);
      await txn.put(revisionKey(file, revision), record);
      await txn.put(headKey(file), {
        revision,
        at,
        note: record.note,
        withdrawn: kind === 'withdraw',
      });
    });

    return {ok: true, revision};
  }

  /// Counts a failed credential attempt, or reads the count.
  ///
  /// Here rather than in KV because the count is a read-modify-write, and two
  /// guesses arriving together against KV would both read the same number and
  /// both write the same increment -- so the limit could be walked past by
  /// simply being fast (AR-2).
  async attempts({scope, action, now}) {
    const held = (await this.storage.get(attemptKey(scope))) ?? null;
    const fresh = held && now - held.since < attemptWindowMs ? held : null;

    if (action === 'clear') {
      await this.storage.delete(attemptKey(scope));
      return {count: 0};
    }
    if (action === 'record') {
      const next = {count: (fresh?.count ?? 0) + 1, since: fresh?.since ?? now};
      await this.storage.put(attemptKey(scope), next);
      return {count: next.count};
    }
    return {count: fresh?.count ?? 0};
  }
}

function json(value) {
  return new Response(JSON.stringify(value ?? null), {
    headers: {'content-type': 'application/json'},
  });
}

// --- what the rest of the Worker talks to ----------------------------------

/// Picks the store the Worker will use.
///
/// `atomic` is the honest bit: it says whether concurrent writes are actually
/// protected, and the panel reports it rather than assuming.
export function contentBackend(env) {
  if (env.CONTENT_STORE) return durableBackend(env);
  if (env.CONTENT) return kvBackend(env);
  return null;
}

function durableBackend(env) {
  const stub = env.CONTENT_STORE.get(env.CONTENT_STORE.idFromName('content'));
  const call = async (body) => {
    const response = await stub.fetch('https://content-store/', {
      method: 'POST',
      body: JSON.stringify(body),
    });
    return response.json();
  };
  return {
    atomic: true,
    readDocument: (file) => call({op: 'read', file}),
    head: (file) => call({op: 'head', file}),
    revisions: (file) => call({op: 'revisions', file}),
    commit: (mutation) => call({op: 'commit', ...mutation}),
    attempts: (scope, action, now) =>
      call({op: 'attempts', scope, action, now}),
  };
}

/// The store as it is today: correct for one writer, and honest that it is
/// only correct for one writer.
function kvBackend(env) {
  const store = env.CONTENT;
  const contentKey = (file) => `content:${file}`;
  const headName = (file) => `revision-head:${file}`;
  const revisionName = (file, revision) =>
    `revision:${file}:${String(revision).padStart(6, '0')}`;

  return {
    atomic: false,
    async readDocument(file) {
      return store.get(contentKey(file), 'json');
    },
    async head(file) {
      return store.get(headName(file), 'json');
    },
    async revisions(file) {
      const listing = await store.list({prefix: `revision:${file}:`});
      const entries = await Promise.all(
        listing.keys.map((entry) => store.get(entry.name, 'json')),
      );
      return entries.filter(Boolean);
    },
    async commit({file, kind, document, note, claims, base, at}) {
      const head = await store.get(headName(file), 'json');
      const current = head?.revision ?? 0;
      if (base !== null && base !== undefined && base !== current) {
        return {
          conflict: true,
          expected: base,
          current,
          document: await store.get(contentKey(file), 'json'),
          changedAt: head?.at ?? null,
        };
      }
      const revision = current + 1;
      const record = {
        revision,
        file,
        at,
        note: note ?? '',
        claims: claims ?? [],
        withdrawal: kind === 'withdraw',
      };
      if (kind !== 'withdraw') record.document = document;
      if (kind === 'rollback') record.restoredFrom = base ?? null;

      if (kind === 'withdraw') await store.delete(contentKey(file));
      else await store.put(contentKey(file), JSON.stringify(document));
      await store.put(revisionName(file, revision), JSON.stringify(record));
      await store.put(
        headName(file),
        JSON.stringify({
          revision,
          at,
          note: record.note,
          withdrawn: kind === 'withdraw',
        }),
      );
      return {ok: true, revision};
    },
    async attempts(scope, action, now) {
      const name = `${attemptKey(scope)}`;
      const held = await env.ANALYTICS.get(name, 'json');
      const fresh = held && now - held.since < attemptWindowMs ? held : null;
      if (action === 'clear') {
        await env.ANALYTICS.delete(name);
        return {count: 0};
      }
      if (action === 'record') {
        const next = {count: (fresh?.count ?? 0) + 1, since: fresh?.since ?? now};
        await env.ANALYTICS.put(name, JSON.stringify(next), {
          expirationTtl: 3600,
        });
        return {count: next.count};
      }
      return {count: fresh?.count ?? 0};
    },
  };
}
