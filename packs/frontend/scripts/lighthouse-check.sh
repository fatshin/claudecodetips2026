#!/usr/bin/env bash
# Lighthouse による performance/a11y/SEO/best-practices 検査
# 使い方:
#   bash scripts/lighthouse-check.sh http://localhost:3000              # 全カテゴリ
#   bash scripts/lighthouse-check.sh http://localhost:3000 perf         # performanceのみ
#   bash scripts/lighthouse-check.sh http://localhost:3000 a11y         # accessibilityのみ
#   bash scripts/lighthouse-check.sh http://localhost:3000 all html     # HTML report出力

set -euo pipefail

URL="${1:?URLが必要}"
CATEGORY="${2:-all}"
FORMAT="${3:-json}"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${OUT_DIR:-./lighthouse-reports}"
mkdir -p "$OUT_DIR"

# カテゴリマッピング
case "$CATEGORY" in
  perf|performance)
    ONLY_FLAG="--only-categories=performance"
    LABEL="performance"
    ;;
  a11y|accessibility)
    ONLY_FLAG="--only-categories=accessibility"
    LABEL="accessibility"
    ;;
  seo)
    ONLY_FLAG="--only-categories=seo"
    LABEL="seo"
    ;;
  bp|best-practices)
    ONLY_FLAG="--only-categories=best-practices"
    LABEL="best-practices"
    ;;
  all|*)
    ONLY_FLAG=""
    LABEL="all"
    ;;
esac

OUTPUT="$OUT_DIR/lighthouse-$LABEL-$TS.$FORMAT"

# Lighthouse 未インストールなら一時的に
if ! command -v lighthouse >/dev/null 2>&1; then
  echo "lighthouse未インストール。npx --yes で実行（初回時間あり）..." >&2
  RUNNER="npx --yes lighthouse"
else
  RUNNER="lighthouse"
fi

# 実行
$RUNNER "$URL" \
  $ONLY_FLAG \
  --output="$FORMAT" \
  --output-path="$OUTPUT" \
  --chrome-flags="--headless --no-sandbox --disable-gpu" \
  --quiet

# JSON ならスコア抽出
if [ "$FORMAT" = "json" ]; then
  echo "" >&2
  echo "=== Scores ===" >&2
  jq -r '
    .categories | to_entries[] |
    .key + ": " + ((.value.score * 100) | floor | tostring) + "/100"
  ' "$OUTPUT" 2>/dev/null || echo "(jq無し、生JSON: $OUTPUT)" >&2

  # 主要メトリクス（performance時）
  if [ "$CATEGORY" = "perf" ] || [ "$CATEGORY" = "performance" ] || [ "$CATEGORY" = "all" ]; then
    echo "" >&2
    echo "=== Core Web Vitals ===" >&2
    jq -r '
      .audits | 
      "LCP (largest-contentful-paint): " + (.["largest-contentful-paint"].displayValue // "N/A") + "\n" +
      "CLS (cumulative-layout-shift):  " + (.["cumulative-layout-shift"].displayValue // "N/A") + "\n" +
      "TBT (total-blocking-time):      " + (.["total-blocking-time"].displayValue // "N/A") + "\n" +
      "INP (interaction-to-next-paint): " + (.["interaction-to-next-paint"].displayValue // "N/A (フィールドデータが必要)") + "\n" +
      "FCP (first-contentful-paint):   " + (.["first-contentful-paint"].displayValue // "N/A") + "\n" +
      "Speed Index:                    " + (.["speed-index"].displayValue // "N/A")
    ' "$OUTPUT" 2>/dev/null || true
  fi
fi

echo "" >&2
echo "✓ saved: $OUTPUT" >&2
