#!/usr/bin/env bash
# 前回snapshotと今回snapshotの差分を抽出
# 使い方: bash scripts/snapshot-diff.sh <new_dir> [<base_dir>]

set -euo pipefail

NEW_DIR="${1:?新snapshot ディレクトリを指定}"
SNAPSHOTS_ROOT="$(dirname "$NEW_DIR")"
BASE_DIR="${2:-}"

# baseが指定されてなければ、NEW_DIRの一つ前を自動選択
if [ -z "$BASE_DIR" ]; then
  BASE_DIR=$(ls -d "$SNAPSHOTS_ROOT"/*/ 2>/dev/null \
    | sort \
    | grep -v "$(basename "$NEW_DIR")" \
    | tail -1 \
    | xargs -I {} dirname {})
  
  if [ -z "$BASE_DIR" ] || [ ! -d "$BASE_DIR" ]; then
    echo "✗ 比較対象のbase snapshotが見つからない（初回実行？）" >&2
    echo "  $NEW_DIR を初回ベースラインとして保存" >&2
    exit 0
  fi
fi

DIFF_DIR="$NEW_DIR/_diff"
mkdir -p "$DIFF_DIR"

echo "=== Diff: $BASE_DIR -> $NEW_DIR ===" >&2

# === GitHub releases差分 ===
echo "→ releases" >&2

if [ -f "$BASE_DIR/claude-code-releases.json" ] && [ -f "$NEW_DIR/claude-code-releases.json" ]; then
  # 新しいタグだけ抽出
  jq --slurpfile base "$BASE_DIR/claude-code-releases.json" '
    map(select(.tagName as $t | ($base[0] | map(.tagName) | index($t) | not)))
  ' "$NEW_DIR/claude-code-releases.json" > "$DIFF_DIR/new-releases.json"
  
  NEW_RELEASES=$(jq 'length' "$DIFF_DIR/new-releases.json")
  echo "  新規release: ${NEW_RELEASES}件" >&2
fi

# === 公式docs差分 ===
echo "→ docs" >&2

mkdir -p "$DIFF_DIR/docs"

if [ -d "$BASE_DIR/docs" ] && [ -d "$NEW_DIR/docs" ]; then
  for new_file in "$NEW_DIR/docs"/*.txt; do
    name="$(basename "$new_file")"
    base_file="$BASE_DIR/docs/$name"
    
    if [ ! -f "$base_file" ]; then
      echo "  + 新規: $name" >&2
      cp "$new_file" "$DIFF_DIR/docs/${name%.txt}-new.txt"
      continue
    fi
    
    # diff取得
    if ! diff -q "$base_file" "$new_file" >/dev/null 2>&1; then
      diff -u "$base_file" "$new_file" > "$DIFF_DIR/docs/${name%.txt}.diff" 2>/dev/null || true
      
      # 50字以上の差分があるか確認（typo fix除外）
      DIFF_SIZE=$(wc -c < "$DIFF_DIR/docs/${name%.txt}.diff")
      if [ "$DIFF_SIZE" -gt 200 ]; then  # diff含むので200程度を閾値に
        echo "  ~ 変更: $name (${DIFF_SIZE} bytes)" >&2
      else
        echo "  · 微小変更: $name (typo修正等)" >&2
        rm -f "$DIFF_DIR/docs/${name%.txt}.diff"
      fi
    fi
  done
fi

# === Boris発信差分 ===
echo "→ boris" >&2

mkdir -p "$DIFF_DIR/boris"

if [ -d "$BASE_DIR/boris" ] && [ -d "$NEW_DIR/boris" ]; then
  shopt -s nullglob
  for new_file in "$NEW_DIR/boris"/*.xml "$NEW_DIR/boris"/*.md "$NEW_DIR/boris"/*.txt; do
    [ -f "$new_file" ] || continue
    name="$(basename "$new_file")"
    base_file="$BASE_DIR/boris/$name"
    
    if [ ! -f "$base_file" ]; then
      cp "$new_file" "$DIFF_DIR/boris/$name"
      echo "  + 新規: $name" >&2
      continue
    fi
    
    if ! diff -q "$base_file" "$new_file" >/dev/null 2>&1; then
      diff -u "$base_file" "$new_file" > "$DIFF_DIR/boris/${name}.diff" 2>/dev/null || true
      echo "  ~ 変更: $name" >&2
    fi
  done
fi

# === メタ情報 ===
cat > "$DIFF_DIR/_summary.json" <<EOF
{
  "base_dir": "$BASE_DIR",
  "new_dir": "$NEW_DIR",
  "diff_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "has_release_changes": $([ -s "$DIFF_DIR/new-releases.json" ] && jq 'length > 0' "$DIFF_DIR/new-releases.json" || echo false),
  "doc_diffs": $(ls "$DIFF_DIR/docs/"*.diff 2>/dev/null | wc -l),
  "boris_diffs": $(ls "$DIFF_DIR/boris/"*.diff 2>/dev/null | wc -l)
}
EOF

echo "" >&2
echo "✓ diff saved to $DIFF_DIR" >&2
cat "$DIFF_DIR/_summary.json" >&2
