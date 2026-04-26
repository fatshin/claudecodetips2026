#!/usr/bin/env bash
# axe-core CLI によるアクセシビリティ詳細検査
# 使い方:
#   bash scripts/axe-check.sh http://localhost:3000
#   bash scripts/axe-check.sh http://localhost:3000 wcag2aa
#   bash scripts/axe-check.sh http://localhost:3000 wcag21aa json

set -euo pipefail

URL="${1:?URLが必要}"
TAGS="${2:-wcag21aa,wcag2a,wcag2aa}"  # デフォルト: WCAG 2.1 AA + WCAG 2.0 A/AA
FORMAT="${3:-text}"  # text|json

TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${OUT_DIR:-./axe-reports}"
mkdir -p "$OUT_DIR"
OUTPUT="$OUT_DIR/axe-$TS.$FORMAT"

# axe-core/cli 確認
if ! command -v axe >/dev/null 2>&1; then
  echo "@axe-core/cli 未インストール。npx --yes で実行（初回時間あり）..." >&2
  RUNNER="npx --yes @axe-core/cli"
else
  RUNNER="axe"
fi

# 実行（CI モードでviolation時にexit 1）
$RUNNER "$URL" \
  --tags "$TAGS" \
  --exit \
  --save "$OUTPUT" \
  $([ "$FORMAT" = "json" ] && echo "--reporter=raw" || echo "") \
  2>&1 | tee "${OUTPUT}.console.log"

EXIT_CODE=${PIPESTATUS[0]}

echo "" >&2
echo "=== Summary ===" >&2

if [ "$FORMAT" = "json" ] && [ -f "$OUTPUT" ]; then
  if command -v jq >/dev/null 2>&1; then
    jq -r '
      "Violations: " + (.violations | length | tostring) + "\n" +
      "Passes:     " + (.passes | length | tostring) + "\n" +
      "Incomplete: " + (.incomplete | length | tostring) + "\n" +
      "Inapplicable: " + (.inapplicable | length | tostring)
    ' "$OUTPUT" 2>/dev/null

    echo "" >&2
    echo "=== Violations by impact ===" >&2
    jq -r '
      .violations | group_by(.impact) | map({
        impact: .[0].impact,
        count: length,
        rules: [.[] | .id]
      }) | .[] | "\(.impact // "unknown"): \(.count) - \(.rules | join(", "))"
    ' "$OUTPUT" 2>/dev/null
  fi
fi

echo "" >&2
echo "✓ saved: $OUTPUT" >&2

exit $EXIT_CODE
