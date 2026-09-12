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
const sessionKey = (id) => `session:${id}`;
const passwordRecordName = 'auth:password';

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
        // One operation, so the document and the revision it is cannot be
        // read either side of somebody else's commit (ARR-3).
        case 'readWithHead':
          return json(await this.readWithHead(asked.file));
        case 'capture':
          return json(await this.capture(asked.files));
        case 'revisions':
          return json(await this.listRevisions(asked.file));
        case 'commit':
          return json(await this.commit(asked));
        case 'attempts':
          return json(await this.attempts(asked));
        case 'session':
          return json(await this.session(asked));
        case 'password':
          return json(await this.password(asked));
        default:
          return json({error: 'Unknown operation'});
      }
    });
  }

  /// A document and its head, read together.
  async readWithHead(file) {
    return {
      document: (await this.storage.get(documentKey(file))) ?? null,
      head: (await this.storage.get(headKey(file))) ?? null,
    };
  }

  /// Every published override at one instant.
  ///
  /// A release assembled from five separate reads can contain half of one
  /// edit and half of another, and a digest over that describes a state that
  /// never existed (ARR-3). This runs inside the serialised section, so
  /// nothing commits part-way through it.
  async capture(files) {
    const documents = {};
    const heads = {};
    for (const file of files) {
      documents[file] = (await this.storage.get(documentKey(file))) ?? null;
      heads[file] = (await this.storage.get(headKey(file))) ?? null;
    }
    return {documents, heads};
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
  async attempts({scope, action, now, limit}) {
    const held = (await this.storage.get(attemptKey(scope))) ?? null;
    const fresh = held && now - held.since < attemptWindowMs ? held : null;

    if (action === 'clear') {
      await this.storage.delete(attemptKey(scope));
      return {count: 0};
    }
    // Check and take a slot in one indivisible step (ARR-1). Reading the
    // count, deciding, and recording the failure afterwards left a window in
    // which every request in a burst read the same number and every one of
    // them went on to derive a key.
    if (action === 'reserve') {
      const count = (fresh?.count ?? 0) + 1;
      await this.storage.put(attemptKey(scope), {
        count,
        since: fresh?.since ?? now,
      });
      return {admitted: count <= limit, count};
    }
    if (action === 'record') {
      const next = {count: (fresh?.count ?? 0) + 1, since: fresh?.since ?? now};
      await this.storage.put(attemptKey(scope), next);
      return {count: next.count};
    }
    return {count: fresh?.count ?? 0};
  }

  /// The whole session lifecycle, in one serialised place.
  ///
  /// Renewal used to be a read from one store and a write to another, so a
  /// logout landing between them was undone by the write that followed it
  /// (ARR-2). Here `use` and `end` cannot interleave: a use that runs first
  /// extends and is then deleted; a use that runs after finds nothing. There
  /// is no ordering in which a revoked session comes back.
  async session({action, id, record, now, idleMs, lifetimeMs}) {
    if (action === 'create') {
      await this.storage.put(sessionKey(id), record);
      return {created: true};
    }
    if (action === 'end') {
      await this.storage.delete(sessionKey(id));
      return {ended: true};
    }
    if (action === 'endAll') {
      const held = await this.storage.list({prefix: 'session:'});
      for (const key of held.keys()) await this.storage.delete(key);
      return {ended: held.size};
    }

    const held = (await this.storage.get(sessionKey(id))) ?? null;
    if (!held) return null;
    if (Date.parse(held.expires) <= now) return null;
    if (Date.parse(held.absoluteExpiry) <= now) return null;

    // Twelve hours idle, not twelve hours old. Renewed only once the
    // remaining window has fallen below half, so ordinary use costs one write
    // rather than one per request, and never past the absolute limit.
    const ceiling = Date.parse(held.absoluteExpiry);
    if (Date.parse(held.expires) - now < idleMs / 2) {
      const extended = Math.min(now + idleMs, ceiling);
      if (extended > Date.parse(held.expires)) {
        held.expires = new Date(extended).toISOString();
        await this.storage.put(sessionKey(id), held);
      }
    }
    return held;
  }

  /// The password verifier, kept beside the sessions it invalidates.
  async password({action, record}) {
    if (action === 'set') {
      await this.storage.put(passwordRecordName, record);
      return {set: true};
    }
    return (await this.storage.get(passwordRecordName)) ?? null;
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
    readWithHead: (file) => call({op: 'readWithHead', file}),
    capture: (files) => call({op: 'capture', files}),
    revisions: (file) => call({op: 'revisions', file}),
    commit: (mutation) => call({op: 'commit', ...mutation}),
    attempts: (scope, action, now, limit) =>
      call({op: 'attempts', scope, action, now, limit}),
    session: (asked) => call({op: 'session', ...asked}),
    password: (action, record) => call({op: 'password', action, record}),
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
    async readWithHead(file) {
      // Two reads, because that is all this store can do. Not atomic, which
      // is one of the things `atomic: false` is telling the panel.
      return {
        document: await store.get(contentKey(file), 'json'),
        head: await store.get(headName(file), 'json'),
      };
    },
    async capture(files) {
      const documents = {};
      const heads = {};
      for (const file of files) {
        documents[file] = await store.get(contentKey(file), 'json');
        heads[file] = await store.get(headName(file), 'json');
      }
      return {documents, heads};
    },
    async attempts(scope, action, now, limit) {
      const name = attemptKey(scope);
      const held = await env.ANALYTICS.get(name, 'json');
      const fresh = held && now - held.since < attemptWindowMs ? held : null;
      if (action === 'clear') {
        await env.ANALYTICS.delete(name);
        return {count: 0};
      }
      if (action === 'reserve' || action === 'record') {
        const count = (fresh?.count ?? 0) + 1;
        await env.ANALYTICS.put(
          name,
          JSON.stringify({count, since: fresh?.since ?? now}),
          {expirationTtl: 3600},
        );
        return {admitted: count <= limit, count};
      }
      return {count: fresh?.count ?? 0};
    },
    async session({action, id, record, now}) {
      const name = `session:${id}`;
      if (action === 'create') {
        await store.put(name, JSON.stringify(record));
        return {created: true};
      }
      if (action === 'end') {
        await store.delete(name);
        return {ended: true};
      }
      if (action === 'endAll') {
        const listing = await store.list({prefix: 'session:'});
        for (const entry of listing.keys) await store.delete(entry.name);
        return {ended: listing.keys.length};
      }
      const held = await store.get(name, 'json');
      if (!held) return null;
      if (Date.parse(held.expires) <= now) return null;
      if (Date.parse(held.absoluteExpiry) <= now) return null;
      // Deliberately no renewal here (ARR-2). Reading and then writing a
      // renewal cannot be made safe against a logout landing between the two,
      // and a stale renewal that resurrects a revoked session is worse than a
      // session that expires twelve hours after it was created. On this store
      // it does. The panel already reports that this deployment is unprotected.
      return held;
    },
    async password(action, record) {
      if (action === 'set') {
        await store.put('auth:password', JSON.stringify(record));
        return {set: true};
      }
      return store.get('auth:password', 'json');
    },
  };
}
