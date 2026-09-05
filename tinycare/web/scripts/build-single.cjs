const fs = require('fs');
const path = require('path');

const distDir = path.join(__dirname, '..', 'dist');
const outDir = path.join(__dirname, '..', 'dist-single');

let html = fs.readFileSync(path.join(distDir, 'index.html'), 'utf8');

html = html.replace(/<script type="module"[^>]*src="\.\/assets\/([^"]+)"[^>]*><\/script>/, (m, name) => {
  const js = fs.readFileSync(path.join(distDir, 'assets', name), 'utf8');
  return `<script type="module" crossorigin>\n${js}\n</script>`;
});

html = html.replace(/<link rel="stylesheet"[^>]*href="\.\/assets\/([^"]+)"[^>]*>/, (m, name) => {
  const css = fs.readFileSync(path.join(distDir, 'assets', name), 'utf8');
  return `<style>\n${css}\n</style>`;
});

fs.mkdirSync(outDir, { recursive: true });
fs.copyFileSync(path.join(distDir, 'favicon.svg'), path.join(outDir, 'favicon.svg'));
fs.writeFileSync(path.join(outDir, 'index.html'), html);

console.log('dist-single regenerated:', (outDir + '\\index.html'), Buffer.byteLength(html), 'bytes');