#!/usr/bin/env bash
# Playwright による e2e smoke test
# 主要ページ表示・主要動線が動くかを最低限確認する
# プロジェクト固有のテストは tests/e2e/ に置く前提

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3000}"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${OUT_DIR:-./e2e-reports/$TS}"
mkdir -p "$OUT_DIR"

# Playwright 確認
if ! command -v npx >/dev/null 2>&1; then
  echo "✗ npx必要" >&2
  exit 1
fi

SCRIPT="$(mktemp "${TMPDIR:-/tmp}/e2e-XXXXXX").js"
trap 'rm -f "$SCRIPT"' EXIT

# プロジェクト固有のテストがあれば優先実行
if [ -d "tests/e2e" ] || [ -d "e2e" ] || [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
  echo "=== プロジェクト固有のPlaywrightテスト実行 ==="
  npx playwright test --reporter=list,html --output="$OUT_DIR" || EXIT=$?
  echo "✓ レポート: $OUT_DIR"
  exit ${EXIT:-0}
fi

# 汎用smoke test（プロジェクト固有が無い場合）
echo "=== 汎用smoke test実行（BASE_URL=$BASE_URL） ==="

cat > "$SCRIPT" <<EOF
const { chromium } = require('playwright');

const SCENARIOS = [
  { name: 'home',       path: '/' },
  { name: 'health',     path: '/health' },
  { name: 'healthz',    path: '/healthz' },
  { name: 'api-health', path: '/api/health' },
];

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  
  const results = [];
  for (const sc of SCENARIOS) {
    const page = await context.newPage();
    const errors = [];
    page.on('console', msg => msg.type() === 'error' && errors.push(msg.text()));
    page.on('pageerror', err => errors.push(err.message));
    
    try {
      const res = await page.goto('$BASE_URL' + sc.path, { 
        waitUntil: 'domcontentloaded',
        timeout: 15000,
      });
      const status = res ? res.status() : 0;
      const ok = status >= 200 && status < 400;
      
      // スクショ保存
      await page.screenshot({ path: '$OUT_DIR/' + sc.name + '.png', fullPage: false });
      
      results.push({
        scenario: sc.name,
        path: sc.path,
        status,
        ok,
        errors: errors.length,
        errorMessages: errors.slice(0, 3),
      });
    } catch (err) {
      results.push({
        scenario: sc.name,
        path: sc.path,
        status: 0,
        ok: false,
        errors: 1,
        errorMessages: [err.message],
      });
    } finally {
      await page.close();
    }
  }
  
  await browser.close();
  
  // 結果出力
  console.log('\n=== Results ===');
  let failedCount = 0;
  for (const r of results) {
    const icon = r.ok ? '✓' : '✗';
    console.log(\`\${icon} \${r.scenario.padEnd(15)} [\${r.status || 'ERR'}] \${r.path}\`);
    if (!r.ok) failedCount++;
    if (r.errorMessages.length) {
      r.errorMessages.forEach(m => console.log('    error: ' + m.slice(0, 80)));
    }
  }
  
  // JSON保存
  const fs = require('fs');
  fs.writeFileSync('$OUT_DIR/results.json', JSON.stringify(results, null, 2));
  
  console.log(\`\n結果: \${results.length - failedCount}/\${results.length} pass\`);
  console.log('レポート: $OUT_DIR');
  
  process.exit(failedCount > 0 ? 1 : 0);
})();
EOF

npx --yes playwright@latest install chromium >/dev/null 2>&1 || true
node "$SCRIPT"
