#!/usr/bin/env bash
# 監視一気通貫: fetch全種 → diff計算 → 分析レポート生成
# 使い方: bash scripts/run-monitoring.sh

set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

KIT_DIR="${KIT_DIR:-packs/monitoring}"
SNAPSHOTS_ROOT="$KIT_DIR/snapshots"
TS="$(date +%Y%m%d-%H%M%S)"
NEW_DIR="$SNAPSHOTS_ROOT/$TS"

mkdir -p "$SNAPSHOTS_ROOT"

echo "================================================"
echo " Claude Code Kit Monitoring - $TS"
echo "================================================"
echo ""

# === Step 1: Fetch ===
echo "### Step 1/4: Fetch sources ###"
bash "$KIT_DIR/scripts/fetch-releases.sh" "$NEW_DIR"
echo ""
bash "$KIT_DIR/scripts/fetch-docs.sh" "$NEW_DIR"
echo ""
bash "$KIT_DIR/scripts/fetch-boris.sh" "$NEW_DIR"
echo ""

# === Step 2: Diff ===
echo "### Step 2/4: Diff calculation ###"
bash "$KIT_DIR/scripts/snapshot-diff.sh" "$NEW_DIR" || {
  echo "✗ diff失敗（初回かも）" >&2
  exit 0
}
echo ""

# === Step 3: 変更があれば分析 ===
DIFF_SUMMARY="$NEW_DIR/_diff/_summary.json"
if [ -f "$DIFF_SUMMARY" ]; then
  HAS_CHANGES=$(jq -r '.has_release_changes or (.doc_diffs > 0) or (.boris_diffs > 0)' "$DIFF_SUMMARY")
  
  if [ "$HAS_CHANGES" = "true" ]; then
    echo "### Step 3/4: Analyze with Claude ###"
    bash "$KIT_DIR/scripts/analyze-update.sh" "$NEW_DIR/_diff" "$NEW_DIR/update-proposal.md"
    echo ""
  else
    echo "### Step 3/4: Skipped (変更なし) ###"
    echo ""
  fi
fi

# === Step 4: 古いsnapshotクリーンアップ ===
echo "### Step 4/4: Cleanup ###"
RETENTION_DAYS=90
find "$SNAPSHOTS_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true
echo "  $RETENTION_DAYS 日以前のsnapshotを削除"
echo ""

# === 完了 ===
echo "================================================"
echo " 完了"
echo "================================================"
echo ""
if [ -f "$NEW_DIR/update-proposal.md" ]; then
  echo "📋 アップデート提案: $NEW_DIR/update-proposal.md"
  echo ""
  echo "--- プレビュー（先頭40行）---"
  head -40 "$NEW_DIR/update-proposal.md"
else
  echo "ℹ 変更なし"
fi
