const fs = require('fs');
const path = require('path');

const distDir = path.join(__dirname, '..', 'dist');
const outDir = path.join(__dirname, '..', 'dist-single');

const htmlFile = path.join(distDir, 'index.html');
if (!fs.existsSync(htmlFile)) {
  console.error(
    `[build-single] ${htmlFile} not found - run "npm run build" first.`
  );
  process.exit(1);
}

let html = fs.readFileSync(htmlFile, 'utf8');

// Vite emits "./assets/..." when `base` is relative and "/assets/..." when it
// is "/", so accept either form.
const ASSET = String.raw`(?:\.\/|\/)assets\/([^"]+)`;

html = html.replace(
  new RegExp(`<script type="module"[^>]*src="${ASSET}"[^>]*><\\/script>`),
  (match, name) => {
    const js = fs.readFileSync(path.join(distDir, 'assets', name), 'utf8');
    return `<script type="module" crossorigin>\n${js}\n</script>`;
  }
);

html = html.replace(
  new RegExp(`<link rel="stylesheet"[^>]*href="${ASSET}"[^>]*>`),
  (match, name) => {
    const css = fs.readFileSync(path.join(distDir, 'assets', name), 'utf8');
    return `<style>\n${css}\n</style>`;
  }
);

// Guard against silently shipping an index.html that still points at separate
// asset files - on a host without them the app renders a blank page.
const leftover = html.match(/assets\/index-[^"']+\.(?:js|css)/g);
if (leftover) {
  console.error(
    '[build-single] Asset inlining failed; index.html still references ' +
      `${leftover.join(', ')}. Refusing to write a broken bundle.`
  );
  process.exit(1);
}

fs.mkdirSync(outDir, { recursive: true });
fs.copyFileSync(path.join(distDir, 'favicon.svg'), path.join(outDir, 'favicon.svg'));
fs.writeFileSync(path.join(outDir, 'index.html'), html);

console.log(
  'dist-single regenerated:',
  outDir + path.sep + 'index.html',
  Buffer.byteLength(html),
  'bytes'
);
