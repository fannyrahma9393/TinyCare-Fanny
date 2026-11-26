#!/usr/bin/env node
/**
 * sync-baseline.mjs
 *
 * One-shot (but idempotent) backfill of the single source of truth:
 * `backend/database/seeders/data/translations-baseline.json`.
 *
 * Web static partials are the current richest source of UI wording, so any
 * key used by the Web app that is missing from the baseline is appended with
 * its exact `id` (Indonesian, == key for UI strings) and `en` value. Existing
 * rows are NEVER touched/rewritten — this tool only grows the baseline.
 *
 * Backfill rule: id == key (Indonesian passthrough), en == Web's current
 * English value for that key (bytes taken from web/src/locales/partials/*).
 *
 * Deterministic: running twice produces byte-identical output (second run
 * adds zero rows). `generated_at` is preserved as-is.
 *
 * Run from the repo root:
 *   node scripts/sync-baseline.mjs
 */
import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { fileURLToPath } from 'node:url';

const here = fileURLToPath(import.meta.url);
const root = join(here, '..', '..');
const baselinePath = join(root, 'backend', 'database', 'seeders', 'data', 'translations-baseline.json');
const webPartialsDir = join(root, 'web', 'src', 'locales', 'partials');

// --- Load current baseline -------------------------------------------------
let baseline = JSON.parse(readFileSync(baselinePath, 'utf8'));
const existingKeys = new Set(baseline.rows.map((r) => r.key));

// --- Import every Web partial (pure ESM data modules) ----------------------
const webId = {};
const webEn = {};
for (const file of readdirSync(webPartialsDir).filter((f) => f.endsWith('.js')).sort()) {
  const mod = await import(`${pathToFileURL(join(webPartialsDir, file)).href}?t=${Date.now()}`);
  Object.assign(webId, mod.default?.id ?? {});
  Object.assign(webEn, mod.default?.en ?? {});
}

// --- Compute missing rows ----------------------------------------------------
const missing = Object.keys(webId).filter((k) => !existingKeys.has(k)).sort();
const added = [];
for (const key of missing) {
  const en = webEn[key] ?? null;
  if (en === null || en === undefined || en === '') {
    throw new Error(`[sync-baseline] Web key has no EN value, cannot backfill: ${JSON.stringify(key)}`);
  }
  added.push({ key, id: webId[key] ?? key, en });
}

// --- Append (existing rows untouched) ----------------------------------------
if (added.length > 0) {
  baseline.rows = baseline.rows.concat(added);
  const out = `${JSON.stringify(baseline, null, 2)}\n`;
  writeFileSync(baselinePath, out, 'utf8');
}

// --- Report ------------------------------------------------------------------
const nowKeys = new Set(baseline.rows.map((r) => r.key));
const dups = checkedDuplicates(baseline.rows.map((r) => r.key));
console.log(`[sync-baseline] baseline rows before: ${existingKeys.size}`);
console.log(`[sync-baseline] backfilled web keys:  ${added.length}`);
console.log(`[sync-baseline] baseline rows after:   ${nowKeys.size}`);
console.log(`[sync-baseline] duplicate keys:        ${dups.length}`);
if (dups.length) console.log(`[sync-baseline] !! dup: ${dups.slice(0, 20).join('\n  ')}`);

function checkedDuplicates(arr) {
  const seen = new Set();
  const dup = [];
  for (const k of arr) {
    if (seen.has(k)) dup.push(k);
    seen.add(k);
  }
  return dup;
}