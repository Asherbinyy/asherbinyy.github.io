/**
 * Checks a document against `content-schema.js`.
 *
 * There is exactly one of these and it runs on the server. The panel does not
 * carry a second copy: it asks `/v1/admin/validate` and draws what comes back.
 * That is deliberate. The defect this replaces (A-F6) is that the Worker
 * checked a publish for valid JSON and a top-level object and nothing else, so
 * the panel could report a successful publish for a document the app then
 * quietly refused to parse. A validator the panel merely agrees with by
 * convention would reintroduce that gap the first time the two drifted.
 *
 * Errors block a publish. Warnings do not: a missing Arabic translation is a
 * fact about the content, not a mistake, and `AGENTS.md` §3 forbids inventing
 * one to clear it.
 */

import {
  assetPattern,
  countryPattern,
  documentsByFile,
  idPattern,
  knownCountries,
  monthPattern,
} from './content-schema.js';

/// Whether [value] is an object that is not an array and not null.
export function plainObject(value) {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/// Whether the owner has left this field empty.
///
/// `null` counts, because the bundled documents write an absent optional link
/// as `null` rather than omitting the key, and both mean the same thing.
function absent(value) {
  return value === undefined || value === null || value === '';
}

class Report {
  errors = [];
  warnings = [];

  add(severity, path, label, message) {
    const issue = {path: path.join('.'), label, message};
    if (severity === 'error') this.errors.push(issue);
    else this.warnings.push(issue);
  }
}

/// Validates [document] against the schema for [file].
///
/// [references] optionally maps a file name to the set of ids it contains, so
/// a stop can be checked for pointing at an application that exists. When a
/// referenced document is not available the reference is reported as
/// unverified rather than silently accepted or wrongly rejected.
export function validateDocument(file, document, {references = null} = {}) {
  const schema = documentsByFile.get(file);
  if (!schema) {
    return {
      errors: [{path: '', label: file, message: 'Not a document this panel edits'}],
      warnings: [],
    };
  }
  const report = new Report();
  if (!plainObject(document)) {
    report.add('error', [], schema.section, 'The document must be an object');
    return {errors: report.errors, warnings: report.warnings};
  }

  const context = {references, seenIds: new Map()};
  checkFields(schema.fields, document, [], schema.section, context, report);
  return {errors: report.errors, warnings: report.warnings};
}

function checkFields(fields, value, path, label, context, report) {
  const declared = new Set(fields.map((field) => field.key));
  for (const key of Object.keys(value)) {
    if (!declared.has(key)) {
      report.add(
        'error',
        [...path, key],
        label,
        `The site has nothing that reads "${key}". Remove it, or ask for the field to be added to the schema before publishing it.`,
      );
    }
  }
  for (const field of fields) {
    checkField(field, value[field.key], [...path, field.key], context, report);
  }
}

function checkField(field, value, path, context, report) {
  const label = field.label ?? path[path.length - 1];
  if (absent(value)) {
    if (field.required === true) {
      report.add('error', path, label, `${label} is required`);
    }
    return;
  }
  check(field, value, path, label, context, report);
}

function check(field, value, path, label, context, report) {
  const fail = (message) => report.add('error', path, label, message);
  const warn = (message) => report.add('warning', path, label, message);

  switch (field.kind) {
    case 'text':
    case 'paragraph': {
      if (typeof value !== 'string') return fail(`${label} must be text`);
      if (value.trim() !== value) warn(`${label} has a space at the start or end`);
      return;
    }
    case 'id': {
      if (typeof value !== 'string' || !idPattern.test(value)) {
        return fail(
          `${label} must be lower case letters, numbers and hyphens, like "my-app"`,
        );
      }
      if (field.unique === true) {
        const scope = path.slice(0, -2).join('.') + '/' + field.key;
        const seen = context.seenIds.get(scope) ?? new Set();
        if (seen.has(value)) fail(`"${value}" is used by more than one entry`);
        seen.add(value);
        context.seenIds.set(scope, seen);
      }
      return;
    }
    case 'localized':
    case 'localizedParagraph': {
      if (!plainObject(value)) {
        return fail(`${label} must have an English and an Arabic value`);
      }
      for (const key of Object.keys(value)) {
        if (key !== 'en' && key !== 'ar') {
          fail(`${label} has an unexpected "${key}"; only en and ar are read`);
        }
      }
      if (typeof value.en !== 'string' || value.en.trim() === '') {
        fail(`${label} needs its English text`);
      }
      if (absent(value.ar)) {
        warn(`${label} has no Arabic. The site will show the English.`);
      } else if (typeof value.ar !== 'string') {
        fail(`${label} in Arabic must be text`);
      }
      return;
    }
    case 'number': {
      if (typeof value !== 'number' || !Number.isFinite(value)) {
        return fail(`${label} must be a number`);
      }
      if (typeof field.min === 'number' && value < field.min) {
        fail(`${label} cannot be below ${field.min}`);
      }
      if (typeof field.max === 'number' && value > field.max) {
        fail(`${label} cannot be above ${field.max}`);
      }
      return;
    }
    case 'boolean': {
      if (typeof value !== 'boolean') fail(`${label} must be yes or no`);
      return;
    }
    case 'url': {
      if (typeof value !== 'string') return fail(`${label} must be a link`);
      let parsed;
      try {
        parsed = new URL(value);
      } catch {
        return fail(`${label} is not a complete address; it needs https://`);
      }
      if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
        fail(`${label} must be an http or https address`);
      } else if (parsed.protocol === 'http:') {
        warn(`${label} is not secure; use https where the site offers it`);
      }
      return;
    }
    case 'email': {
      if (typeof value !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
        fail(`${label} is not an email address`);
      }
      return;
    }
    case 'tel': {
      if (typeof value !== 'string' || !/^\+[0-9 ]{6,}$/.test(value)) {
        fail(`${label} must start with + and its country code`);
      }
      return;
    }
    case 'asset': {
      if (typeof value !== 'string' || !assetPattern.test(value)) {
        fail(
          `${label} must be an uploaded file or a path inside the app's assets`,
        );
      }
      return;
    }
    case 'choice': {
      const allowed = field.options.map((option) => option.value);
      if (!allowed.includes(value)) {
        fail(`${label} must be one of: ${allowed.join(', ')}`);
      }
      return;
    }
    case 'choiceList': {
      if (!Array.isArray(value)) return fail(`${label} must be a list`);
      const allowed = field.options.map((option) => option.value);
      const seen = new Set();
      value.forEach((entry, index) => {
        if (!allowed.includes(entry)) {
          report.add(
            'error',
            [...path, index],
            label,
            `${label} must be one of: ${allowed.join(', ')}`,
          );
        }
        if (seen.has(entry)) {
          report.add('error', [...path, index], label, `${entry} is listed twice`);
        }
        seen.add(entry);
      });
      if (field.required === true && value.length === 0) {
        fail(`${label} needs at least one`);
      }
      return;
    }
    case 'country': {
      if (typeof value !== 'string' || !countryPattern.test(value)) {
        return fail(`${label} must be a two-letter code, like GB`);
      }
      if (!knownCountries.includes(value)) {
        warn(`The site has no flag for ${value}; it will show the code`);
      }
      return;
    }
    case 'month': {
      if (typeof value !== 'string' || !monthPattern.test(value)) {
        fail(`${label} must be a year and month, like 2024-03`);
      }
      return;
    }
    case 'coords': {
      if (!Array.isArray(value) || value.length !== 2) {
        return fail(`${label} must be a latitude and a longitude`);
      }
      const [lat, lon] = value;
      if (typeof lat !== 'number' || !Number.isFinite(lat) || Math.abs(lat) > 90) {
        fail('Latitude must be between -90 and 90');
      }
      if (typeof lon !== 'number' || !Number.isFinite(lon) || Math.abs(lon) > 180) {
        fail('Longitude must be between -180 and 180');
      }
      return;
    }
    case 'reference': {
      if (typeof value !== 'string') return fail(`${label} must be an identifier`);
      const known = context.references?.[field.references];
      if (!known) {
        return warn(
          `Could not check that "${value}" still exists in ${field.references}`,
        );
      }
      if (!known.includes(value)) {
        fail(`Nothing in ${field.references} has the identifier "${value}"`);
      }
      return;
    }
    case 'list': {
      if (!Array.isArray(value)) return fail(`${label} must be a list`);
      if (field.required === true && value.length === 0) {
        fail(`${label} needs at least one entry`);
      }
      value.forEach((entry, index) => {
        const item = {...field.of, label: field.of.label ?? label};
        if (absent(entry) && item.kind !== 'boolean') {
          return report.add(
            'error',
            [...path, index],
            label,
            `Entry ${index + 1} of ${label} is empty`,
          );
        }
        check(item, entry, [...path, index], item.label, context, report);
      });
      return;
    }
    case 'object': {
      if (!plainObject(value)) return fail(`${label} must be a group of fields`);
      checkFields(field.fields, value, path, label, context, report);
      return;
    }
    case 'map': {
      if (!plainObject(value)) return fail(`${label} must be a group of links`);
      const allowed = field.keys.map((entry) => entry.value);
      for (const [key, entry] of Object.entries(value)) {
        if (!allowed.includes(key)) {
          report.add(
            'error',
            [...path, key],
            label,
            `${label} has no "${key}"; expected one of ${allowed.join(', ')}`,
          );
          continue;
        }
        const name = field.keys.find((option) => option.value === key).label;
        if (absent(entry)) continue;
        check({...field.of, label: name}, entry, [...path, key], name, context, report);
      }
      return;
    }
    default:
      fail(`No rule for a field of kind "${field.kind}"`);
  }
}

/// Every value in [document] the owner has to be able to point at a source for.
///
/// A figure is a claim. The old panel asked for a source when a *number*
/// changed, which missed every one written as text -- "5+", "50% retention
/// lift", "25 apps" -- and those are most of them. This finds them by what the
/// schema says a field is, not by the JavaScript type of its value.
export function collectClaims(file, document) {
  const schema = documentsByFile.get(file);
  if (!schema || !plainObject(document)) return [];
  const found = [];
  walkClaims(schema.fields, document, [], found);
  return found;
}

function walkClaims(fields, value, path, found) {
  if (!plainObject(value)) return;
  for (const field of fields) {
    const at = [...path, field.key];
    const held = value[field.key];
    if (field.claim === true && !absent(held)) {
      found.push({path: at.join('.'), label: field.label, value: held});
      continue;
    }
    if (field.kind === 'object') walkClaims(field.fields, held, at, found);
    if (field.kind === 'list' && Array.isArray(held)) {
      held.forEach((entry, index) => {
        if (field.of.kind === 'object') {
          walkClaims(field.of.fields, entry, [...at, index], found);
        }
      });
    }
  }
}

/// Every leaf that differs between two documents.
///
/// Server-side because the review sheet and the provenance rule both need it
/// and they must agree: a change the review sheet does not show is a change
/// published without being seen.
export function differences(before, after, path = []) {
  if (JSON.stringify(before) === JSON.stringify(after)) return [];
  const both =
    plainObject(before) && plainObject(after);
  const lists = Array.isArray(before) && Array.isArray(after);
  if (!both && !lists) {
    return [{path: path.join('.'), before: before ?? null, after: after ?? null}];
  }
  const keys = lists
    ? [...Array(Math.max(before.length, after.length)).keys()]
    : [...new Set([...Object.keys(before), ...Object.keys(after)])];
  const out = [];
  for (const key of keys) {
    out.push(...differences(before?.[key], after?.[key], [...path, key]));
  }
  return out;
}

/// The claims whose value is not the same as it was.
///
/// Publishing one of these needs a source. Publishing a claim that has not
/// moved does not: the owner already gave a source when he set it.
export function changedClaims(file, before, after) {
  const previous = new Map(
    collectClaims(file, before).map((claim) => [claim.path, claim.value]),
  );
  return collectClaims(file, after)
    .filter((claim) => JSON.stringify(previous.get(claim.path)) !== JSON.stringify(claim.value))
    .map((claim) => ({...claim, was: previous.get(claim.path) ?? null}));
}
