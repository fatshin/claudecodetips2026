#!/usr/bin/env bash
# GitHub releases / commits を取得して snapshot 保存
# 使い方: bash scripts/fetch-releases.sh [output_dir]

set -euo pipefail

OUT_DIR="${1:-packs/monitoring/snapshots/$(date +%Y%m%d)}"
mkdir -p "$OUT_DIR"

if ! command -v gh >/dev/null 2>&1; then
  echo "✗ gh CLI が必要" >&2
  exit 1
fi

# === claude-code releases ===
echo "→ claude-code releases" >&2
gh release list --repo anthropics/claude-code --limit 30 \
  --json tagName,publishedAt,name,body \
  > "$OUT_DIR/claude-code-releases.json"

# 過去30日分を抽出
THIRTY_DAYS_AGO="$(date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
  || date -u -v-30d +%Y-%m-%dT%H:%M:%SZ)"

jq --arg since "$THIRTY_DAYS_AGO" \
   '[.[] | select(.publishedAt > $since)]' \
   "$OUT_DIR/claude-code-releases.json" \
   > "$OUT_DIR/claude-code-recent.json"

RECENT_COUNT=$(jq 'length' "$OUT_DIR/claude-code-recent.json")
echo "  直近30日: ${RECENT_COUNT}件" >&2

# === claude-code-action releases ===
echo "→ claude-code-action releases" >&2
gh release list --repo anthropics/claude-code-action --limit 20 \
  --json tagName,publishedAt,name,body \
  > "$OUT_DIR/claude-code-action-releases.json" 2>/dev/null || \
  echo '[]' > "$OUT_DIR/claude-code-action-releases.json"

# === claude-code-docs commits（リポジトリがあれば）===
echo "→ claude-code-docs commits" >&2
gh api repos/anthropics/claude-code-docs/commits \
  --jq '[.[] | {sha, date: .commit.author.date, message: .commit.message}]' \
  > "$OUT_DIR/claude-code-docs-commits.json" 2>/dev/null \
  || echo '[]' > "$OUT_DIR/claude-code-docs-commits.json"

echo "" >&2
echo "✓ saved to $OUT_DIR" >&2
ls -la "$OUT_DIR" >&2
