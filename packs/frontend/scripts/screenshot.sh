#!/usr/bin/env bash
# Playwright によるスクショ取得
# 使い方:
#   bash scripts/screenshot.sh http://localhost:3000
#   bash scripts/screenshot.sh http://localhost:3000 /tmp/home.png
#   bash scripts/screenshot.sh http://localhost:3000 /tmp/home.png "1920,1080"
#   bash scripts/screenshot.sh http://localhost:3000 /tmp/home.png "375,667" mobile

set -euo pipefail

URL="${1:?URLが必要}"
OUTPUT="${2:-/tmp/screenshot-$(date +%s).png}"
VIEWPORT="${3:-1280,800}"
DEVICE="${4:-desktop}"

# Playwright がインストールされているか確認
if ! command -v npx >/dev/null 2>&1; then
  echo "✗ npx必要 (Node.js)" >&2
  exit 1
fi

# 一時的なPlaywrightスクリプト生成
SCRIPT="$(mktemp "${TMPDIR:-/tmp}/screenshot-XXXXXX").js"
trap 'rm -f "$SCRIPT"' EXIT

VP_W="$(echo "$VIEWPORT" | cut -d, -f1)"
VP_H="$(echo "$VIEWPORT" | cut -d, -f2)"

_jsesc() { printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()), end="")'; }

JS_URL=$(_jsesc "$URL")
JS_OUTPUT=$(_jsesc "$OUTPUT")
JS_DEVICE=$(_jsesc "$DEVICE")

cat > "$SCRIPT" <<EOF
const { chromium, devices } = require('playwright');
(async () => {
  const url = ${JS_URL};
  const output = ${JS_OUTPUT};
  const device = ${JS_DEVICE};
  const vpW = ${VP_W}, vpH = ${VP_H};

  const browser = await chromium.launch();
  const context = device === 'mobile'
    ? await browser.newContext({ ...devices['iPhone 13'] })
    : await browser.newContext({ viewport: { width: vpW, height: vpH } });
  const page = await context.newPage();

  const errors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push('CONSOLE: ' + msg.text());
  });
  page.on('pageerror', err => errors.push('PAGEERROR: ' + err.message));
  page.on('requestfailed', req => errors.push('REQ_FAILED: ' + req.url() + ' ' + (req.failure()?.errorText || '')));

  await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(500);
  await page.screenshot({ path: output, fullPage: true });
  await browser.close();

  console.log(JSON.stringify({ url, output, viewport: vpW+'x'+vpH, device, errors }, null, 2));
})();
EOF

# Playwright未インストールならインストール
if ! npm list -g playwright >/dev/null 2>&1 && ! npm list playwright >/dev/null 2>&1; then
  echo "Playwright未インストール。npx --yes で実行（初回ダウンロード時間あり）..." >&2
fi

npx --yes playwright@latest install chromium >/dev/null 2>&1 || true
node "$SCRIPT"

echo "" >&2
echo "✓ saved: $OUTPUT" >&2
