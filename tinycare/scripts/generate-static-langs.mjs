#!/usr/bin/env node
/**
 * generate-static-langs.mjs
 *
 * Regenerates the Web + Flutter STATIC fallback catalogs from a single source:
 * `backend/database/seeders/data/translations-baseline.json`.
 *
 *   translations-baseline.json
 *           ├──► web/src/locales/partials/*.js     (id + en)
 *           └──► mobile/lib/l10n/partials/*.dart   (en maps; id is implicitly
 *                                                    the key in the Flutter
 *                                                    AppStrings design)
 *
 * Grouping is derived from the CURRENT partial membership of each platform
 * (owner == the partial that already contains the key). Keys without an owner
 * are placed into a new `misc` group (web: partials/misc.js,
 * flutter: partials/misc.dart). Baseline values are the source of truth —
 * any previous EN drift between the two platforms is aligned to the baseline.
 *
 * This tool does NOT touch the Laravel DB, the translation API, the seeder,
 * the runtime overlay services, or authentication/authorization. It only
 * rewrites the static fallback bundles.
 *
 * Deterministic: same input => same output, key order is sorted, no
 * timestamps. Safe to run repeatedly.
 *
 * Run from the repo root:
 *   node scripts/generate-static-langs.mjs
 */
import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { join, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = fileURLToPath(import.meta.url);
const root = join(here, '..', '..');
const baselinePath = join(root, 'backend', 'database', 'seeders', 'data', 'translations-baseline.json');
const webDir = join(root, 'web', 'src', 'locales', 'partials');
const flutterDir = join(root, 'mobile', 'lib', 'l10n', 'partials');

const MISC = 'misc';
const WEB_MISC_HEADER =
  '// Strings without a dedicated partial owner (cross-platform + server-only).\n' +
  '// Generated from the single source `backend/database/seeders/data/translations-baseline.json`.';
const FLUTTER_MISC_HEADER =
  '// misc strings (cross-platform + server-only keys without a dedicated partial owner).';

// ---------------------------------------------------------------------------
// Escape helpers
// ---------------------------------------------------------------------------
const ES = {
  '\\': '\\\\',
  "'": "\\'",
  '\n': '\\n',
  '\r': '\\r',
  '\t': '\\t',
  '\u2028': '\\u2028',
  '\u2029': '\\u2029',
};
const jsEscape = (s) => s.replace(/[\\'\n\r\t\u2028\u2029]/g, (ch) => ES[ch]);

const DS = {
  '\\': '\\\\',
  "'": "\\'",
  '$': '\\$',
  '\n': '\\n',
  '\r': '\\r',
  '\t': '\\t',
  '\u2028': '\\u2028',
  '\u2029': '\\u2029',
};
const dartEscape = (s) => s.replace(/[\\'$\n\r\t\u2028\u2029]/g, (ch) => DS[ch]);

// ---------------------------------------------------------------------------
// Parsers: read existing JS / Dart literal maps back into plain JS objects
// ---------------------------------------------------------------------------
function readString(src, i, quotes) {
  const q = src[i];
  if (!quotes.includes(q)) throw new Error(`expected string literal at offset ${i}, found ${JSON.stringify(src[i])}`);
  let out = '';
  i += 1;
  while (i < src.length) {
    const c = src[i];
    if (c === '\\') {
      const n = src[i + 1];
      if (n === '\\') out += '\\';
      else if (n === "'") out += "'";
      else if (n === '"') out += '"';
      else if (n === 'n') out += '\n';
      else if (n === 'r') out += '\r';
      else if (n === 't') out += '\t';
      else if (n === 'u') {
        const hex = src.slice(i + 2, i + 6);
        out += String.fromCharCode(parseInt(hex, 16));
        i += 6;
      } else out += n;
      i += 2;
    } else if (c === q) {
      return { value: out, end: i + 1 };
    } else {
      out += c;
      i += 1;
    }
  }
  throw new Error('unterminated string literal');
}

function skipWs(src, i) {
  while (i < src.length) {
    const c = src[i];
    if (/\s/.test(c)) {
      i += 1;
    } else if (c === '/' && src[i + 1] === '/') {
      i = src.indexOf('\n', i);
      if (i === -1) i = src.length;
    } else if (c === '/' && src[i + 1] === '*') {
      const end = src.indexOf('*/', i + 2);
      if (end === -1) throw new Error('unterminated block comment');
      i = end + 2;
    } else {
      break;
    }
  }
  return i;
}

function readObjectEntries(src, openIdx, quotes) {
  const entries = {};
  let i = openIdx + 1;
  while (i < src.length) {
    i = skipWs(src, i);
    if (src[i] === '}') break;
    const key = readString(src, i, quotes);
    i = skipWs(src, key.end);
    if (src[i] !== ':') throw new Error(`expected ':' after key at offset ${i}`);
    i = skipWs(src, i + 1);
    const val = readString(src, i, quotes);
    entries[key.value] = val.value;
    i = skipWs(src, val.end);
    if (src[i] === ',') i += 1;
  }
  return entries;
}

function parseWebModule(src) {
  const out = { id: {}, en: {} };
  for (const section of ['id', 'en']) {
    const marker = `${section}: {`;
    const p = src.indexOf(marker);
    if (p === -1) throw new Error(`web partial missing "${marker}"`);
    const open = src.indexOf('{', p);
    out[section] = readObjectEntries(src, open, "'\"");
  }
  return out;
}

function parseDartMap(src) {
  const decl = /const\s+Map<String,\s*String>\s+(\w+)\s*=\s*\{/.exec(src);
  if (!decl) throw new Error('dart partial missing "const Map<String, String> NAME = {"');
  const open = src.indexOf('{', decl.index);
  const entries = readObjectEntries(src, open, "'");
  return { name: decl[1], entries };
}

function extractHeader(src, startMarker) {
  const idx = src.indexOf(startMarker);
  return idx === -1 ? '' : src.slice(0, idx);
}

// ---------------------------------------------------------------------------
// Placeholder helpers ({{name}} for UI, {name} for server notifications)
// ---------------------------------------------------------------------------
function placeholders(text, wrapper) {
  const set = new Set();
  if (wrapper === 'double') {
    const re = /\{\{([^}]+)\}\}/g;
    let m;
    while ((m = re.exec(text))) set.add(`{{${m[1]}}}`);
  } else {
    const re = /\{([a-zA-Z_][a-zA-Z0-9_]*)\}/g;
    let m;
    while ((m = re.exec(text))) set.add(`{${m[1]}}`);
  }
  return [...set].sort();
}
const pld = (s) => placeholders(s, 'double');
const pls = (s) => placeholders(s, 'single');
const eqSet = (a, b) => a.length === b.length && a.every((x, i) => x === b[i]);

// ---------------------------------------------------------------------------
// 1. Load baseline (single source of truth)
// ---------------------------------------------------------------------------
const baseline = JSON.parse(readFileSync(baselinePath, 'utf8'));
const rows = baseline.rows.filter((r) => typeof r.key === 'string' && r.key !== '');
const byKey = new Map(rows.map((r) => [r.key, r]));
const baseKeys = rows.map((r) => r.key);

const dupKeys = baseKeys.filter((k, i) => baseKeys.indexOf(k) !== i);
if (dupKeys.length) throw new Error(`baseline has duplicate keys: ${dupKeys.slice(0, 20).join(', ')}`);
for (const r of rows) {
  if (typeof r.id !== 'string' || r.id === '') throw new Error(`baseline row missing id: ${JSON.stringify(r.key)}`);
  if (typeof r.en !== 'string' || r.en === '') throw new Error(`baseline row missing en: ${JSON.stringify(r.key)}`);
}

// ---------------------------------------------------------------------------
// 2. Derive ownership from CURRENT partial membership (both platforms)
// ---------------------------------------------------------------------------
const webFiles = readdirSync(webDir).filter((f) => f.endsWith('.js')).sort();
const webOwner = new Map();
const webDroppedDups = [];
for (const f of webFiles) {
  const src = readFileSync(join(webDir, f), 'utf8');
  const parsed = parseWebModule(src);
  for (const k of Object.keys(parsed.id)) {
    if (webOwner.has(k)) {
      webDroppedDups.push(`${basename(f, '.js')} (already owned by ${webOwner.get(k)})`);
      continue;
    }
    webOwner.set(k, basename(f, '.js'));
  }
}

const flutterFiles = readdirSync(flutterDir).filter((f) => f.endsWith('.dart')).sort();
const flutterOwner = new Map();
const flutterVar = new Map();
const flutterHeader = new Map();
const flutterDroppedDups = [];
for (const f of flutterFiles) {
  const src = readFileSync(join(flutterDir, f), 'utf8');
  const { name, entries } = parseDartMap(src);
  flutterVar.set(basename(f, '.dart'), name);
  flutterHeader.set(basename(f, '.dart'), extractHeader(src, 'const Map<String, String>'));
  for (const k of Object.keys(entries)) {
    if (flutterOwner.has(k)) {
      flutterDroppedDups.push(`${basename(f, '.dart')} (already owned by ${flutterOwner.get(k)})`);
      continue;
    }
    flutterOwner.set(k, basename(f, '.dart'));
  }
}

// 3. Guard: every UI key must exist in the baseline before generation.
const webKeys = [...webOwner.keys()].sort();
const missingWebInBase = webKeys.filter((k) => !byKey.has(k));
const missingFlutterInBase = [...flutterOwner.keys()].filter((k) => !byKey.has(k));
if (missingWebInBase.length || missingFlutterInBase.length) {
  console.error(`[generate] baseline is missing keys — run "node scripts/sync-baseline.mjs" first.`);
  if (missingWebInBase.length) console.error(`  web missing: ${missingWebInBase.length}`);
  if (missingFlutterInBase.length) console.error(`  flutter missing: ${missingFlutterInBase.length}`);
  process.exit(1);
}

// ---------------------------------------------------------------------------
// 4. Group baseline rows per platform
// ---------------------------------------------------------------------------
function groupBy(ownerMap, fallbackHeader) {
  const groups = new Map(); // name -> { id, en } both as Map
  const add = (name) => {
    if (!groups.has(name)) groups.set(name, { id: new Map(), en: new Map() });
    return groups.get(name);
  };
  for (const k of baseKeys) {
    const owner = ownerMap.get(k);
    if (owner && owner !== MISC) {
      add(owner);
    } else {
      add(MISC);
    }
  }
  // fill values from baseline (source of truth)
  for (const r of rows) {
    const owner = ownerMap.get(r.key);
    const name = owner && owner !== MISC ? owner : MISC;
    const g = groups.get(name);
    g.id.set(r.key, r.id);
    g.en.set(r.key, r.en);
  }
  return groups;
}

const webGroups = groupBy(webOwner);
const flutterGroups = groupBy(flutterOwner);

// ---------------------------------------------------------------------------
// 5. Render + write
// ---------------------------------------------------------------------------
function renderWeb(name) {
  const g = webGroups.get(name);
  const keys = [...g.id.keys()].sort();
  const line = (map) => keys.map((k) => `    '${jsEscape(k)}': '${jsEscape(map.get(k))}',`).join('\n');
  const miscExists = readdirSync(webDir).includes(`${MISC}.js`);
  const header =
    name === MISC
      ? (miscExists ? extractHeader(readFileSync(join(webDir, `${MISC}.js`), 'utf8'), 'export default') : '')
      : extractHeader(readFileSync(join(webDir, `${name}.js`), 'utf8'), 'export default');
  const hdr = header.length ? header : `${WEB_MISC_HEADER}\n`;
  return `${hdr}export default {\n  id: {\n${line(g.id)}\n  },\n  en: {\n${line(g.en)}\n  },\n};\n`;
}

function dartVarName(name) {
  const cache = flutterVar.get(name);
  if (cache) return cache;
  return `${name.split('_').filter(Boolean).map((p, i) => (i === 0 ? p : p[0].toUpperCase() + p.slice(1))).join('')}En`;
}

function renderFlutter(name) {
  const g = flutterGroups.get(name);
  const keys = [...g.en.keys()].sort();
  const line = keys.map((k) => `  '${dartEscape(k)}': '${dartEscape(g.en.get(k))}',`).join('\n');
  const varName = dartVarName(name);
  const miscExists = readdirSync(flutterDir).includes(`${MISC}.dart`);
  let header =
    name === MISC && miscExists
      ? extractHeader(readFileSync(join(flutterDir, `${MISC}.dart`), 'utf8'), 'const Map<String, String>')
      : (flutterHeader.get(name) ?? '');
  if (!header.length && !(name === MISC && !miscExists)) {
    console.warn(`[generate] WARN: no header preserved for flutter partial '${name}' (using default).`);
  }
  const hdr = header.length ? header : `${FLUTTER_MISC_HEADER}\n`;
  return `${hdr}const Map<String, String> ${varName} = {\n${line}\n};\n`;
}

for (const [name] of webGroups) {
  writeFileSync(join(webDir, `${name}.js`), renderWeb(name), 'utf8');
}
for (const [name] of flutterGroups) {
  writeFileSync(join(flutterDir, `${name}.dart`), renderFlutter(name), 'utf8');
}

// ---------------------------------------------------------------------------
// 6. Validation (re-parse generated output, compare against baseline)
// ---------------------------------------------------------------------------
console.log(`[generate] baseline rows:          ${rows.length}`);
console.log(`[generate] web output files:       ${[...webGroups.keys()].length}`);
console.log(`[generate] flutter output files:   ${[...flutterGroups.keys()].length}`);
if (webDroppedDups.length) {
  console.log(`[generate] dup web keys de-duplicated (kept first owner): ${webDroppedDups.length}`);
  for (const d of webDroppedDups) console.log(`    ${d}`);
}
if (flutterDroppedDups.length) {
  console.log(`[generate] dup flutter keys de-duplicated (kept first owner): ${flutterDroppedDups.length}`);
  for (const d of flutterDroppedDups) console.log(`    ${d}`);
}

const problems = [];
const webOut = new Map();
for (const [name] of webGroups) {
  const p = parseWebModule(readFileSync(join(webDir, `${name}.js`), 'utf8'));
  for (const k of Object.keys(p.id)) webOut.set(k, p.en[k]);
}
const flutterOut = new Map();
for (const [name] of flutterGroups) {
  const { entries } = parseDartMap(readFileSync(join(flutterDir, `${name}.dart`), 'utf8'));
  for (const k of Object.keys(entries)) flutterOut.set(k, entries[k]);
}

const webMissing = baseKeys.filter((k) => !webOut.has(k));
const webExtra = [...webOut.keys()].filter((k) => !byKey.has(k));
const flMissing = baseKeys.filter((k) => !flutterOut.has(k));
const flExtra = [...flutterOut.keys()].filter((k) => !byKey.has(k));
if (webMissing.length || webExtra.length) problems.push(`web key set mismatch: missing=${webMissing.length} extra=${webExtra.length}`);
if (flMissing.length || flExtra.length) problems.push(`flutter key set mismatch: missing=${flMissing.length} extra=${flExtra.length}`);

for (const k of baseKeys) {
  if (webOut.get(k) !== byKey.get(k).en) problems.push(`web en mismatch for ${JSON.stringify(k)}`);
  if (flutterOut.get(k) !== byKey.get(k).en) problems.push(`flutter en mismatch for ${JSON.stringify(k)}`);
}

// placeholders: baseline id vs en (both styles), then generated == baseline parts
let phIdEn = 0;
const phExamples = [];
for (const r of rows) {
  const d = pld(r.id);
  const de = pld(r.en);
  if (!eqSet(d, de)) {
    phIdEn += 1;
    if (phExamples.length < 8) phExamples.push({ key: r.key, id: d, en: de });
  }
  const s = pls(r.id);
  const se = pls(r.en);
  if (!eqSet(s, se) && phExamples.length < 12) phExamples.push({ key: r.key, idSingles: s, enSingles: se });
}
if (phIdEn) problems.push(`rows where {{...}} placeholders differ id vs en: ${phIdEn}`);

console.log(`[generate] web en coverage:        ${webOut.size}/${rows.length}`);
console.log(`[generate] flutter en coverage:    ${flutterOut.size}/${rows.length}`);
console.log(`[generate] {{...}} id/en mismatch:  ${phIdEn}`);
if (phExamples.length) console.log(`[generate] placeholder examples:\n${phExamples.map((e) => JSON.stringify(e)).join('\n')}`);
if (problems.length) {
  console.error(`[generate] !! validation problems (${problems.length}):`);
  for (const p of problems) console.error(`  - ${p}`);
  process.exit(1);
}
console.log(`[generate] OK — output matches baseline (0 missing, 0 extra, en identical).`);