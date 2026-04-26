#!/usr/bin/env bash
# Boris Cherny の X / Threads 発信を取得
# robots.txt問題で直接 web fetch は困難。代替手段を順に試す:
#   1. RSS bridge service（rsshub.app等）
#   2. nitter mirror
#   3. Gemini CLI でweb検索
#   4. 手動投入ファイル
#
# 使い方: bash scripts/fetch-boris.sh [output_dir]

set -euo pipefail

OUT_DIR="${1:-packs/monitoring/snapshots/$(date +%Y%m%d)}"
mkdir -p "$OUT_DIR/boris"

SUCCESS_COUNT=0

# === Option 1: RSS bridge ===
echo "=== Option 1: RSS bridge ===" >&2

RSS_SOURCES=(
  "https://rsshub.app/twitter/user/bcherny"
  "https://rsshub.app/threads/boris_cherny"
)

for rss_url in "${RSS_SOURCES[@]}"; do
  name="$(echo "$rss_url" | md5sum | cut -d' ' -f1 | head -c8)"
  echo "  → $rss_url" >&2
  if curl -sf -m 10 "$rss_url" -o "$OUT_DIR/boris/rss-$name.xml" 2>/dev/null; then
    if [ -s "$OUT_DIR/boris/rss-$name.xml" ]; then
      echo "    ✓ 取得成功" >&2
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
      rm -f "$OUT_DIR/boris/rss-$name.xml"
      echo "    ✗ 空" >&2
    fi
  else
    echo "    ✗ 失敗" >&2
  fi
done

# === Option 2: nitter mirrors ===
echo "" >&2
echo "=== Option 2: nitter mirrors ===" >&2

NITTER_MIRRORS=(
  "https://nitter.privacydev.net/bcherny/rss"
  "https://nitter.poast.org/bcherny/rss"
  "https://nitter.net/bcherny/rss"
)

for mirror_url in "${NITTER_MIRRORS[@]}"; do
  name="$(echo "$mirror_url" | md5sum | cut -d' ' -f1 | head -c8)"
  echo "  → $mirror_url" >&2
  if curl -sf -m 10 "$mirror_url" -o "$OUT_DIR/boris/nitter-$name.xml" 2>/dev/null; then
    if [ -s "$OUT_DIR/boris/nitter-$name.xml" ] && grep -q '<item>' "$OUT_DIR/boris/nitter-$name.xml" 2>/dev/null; then
      echo "    ✓ 取得成功" >&2
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      break  # 1つ成功すれば十分
    else
      rm -f "$OUT_DIR/boris/nitter-$name.xml"
      echo "    ✗ 内容なし" >&2
    fi
  else
    echo "    ✗ 失敗（mirror閉鎖の可能性）" >&2
  fi
done

# === Option 3: Gemini CLI 経由でweb検索 ===
echo "" >&2
echo "=== Option 3: Gemini CLI web検索 ===" >&2

if command -v gemini >/dev/null 2>&1; then
  PROMPT='Boris Cherny (Anthropic, Claude Codeの作者)が過去30日に発信した内容を以下のソースから検索して要約せよ:

- X.com/bcherny
- threads.net/@boris_cherny

重要そうな発言（Claude Codeの新機能、運用Tips、ベストプラクティス）を最大10件、以下のJSON形式で返せ:

[
  {
    "date": "YYYY-MM-DD推定",
    "source": "x|threads",
    "topic": "短い要約",
    "url": "推定URL",
    "key_points": ["...", "..."]
  }
]

確証のない情報は含めない。見つからなければ空配列 [] を返す。
'
  
  echo "  → Gemini CLIで検索中..." >&2
  if gemini -p "$PROMPT" --output-format json 2>/dev/null \
     | jq -r '.response' \
     > "$OUT_DIR/boris/gemini-search.md" 2>/dev/null; then
    if [ -s "$OUT_DIR/boris/gemini-search.md" ]; then
      echo "    ✓ Gemini検索結果取得" >&2
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    fi
  else
    echo "    ✗ Gemini CLI実行失敗" >&2
  fi
else
  echo "  ⚠ Gemini CLI未インストール（npm install -g @google/gemini-cli）" >&2
fi

# === Option 4: 手動投入ファイル ===
echo "" >&2
echo "=== Option 4: 手動投入ファイル ===" >&2

MANUAL_FILE="docs/manual-boris-input.md"
if [ -f "$MANUAL_FILE" ]; then
  cp "$MANUAL_FILE" "$OUT_DIR/boris/manual-input.md"
  echo "  ✓ $MANUAL_FILE をコピー" >&2
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
  echo "  ⚠ $MANUAL_FILE が存在しない" >&2
  echo "    手動でBoris発言を貼ったファイルを作っておくと取り込まれる" >&2
fi

# === サマリー ===
echo "" >&2
echo "=== サマリー ===" >&2
echo "成功ソース数: $SUCCESS_COUNT" >&2

if [ "$SUCCESS_COUNT" -eq 0 ]; then
  cat >&2 <<EOF

⚠ Boris発信の自動取得に全て失敗。以下の対処を:

1. rsshub.app の self-host instance を立てる
2. https://docs.rsshub.app/install/ 参照
3. または X API（developer登録後、月間50ツイート無料枠あり）
4. または手動: $MANUAL_FILE にBoris発言を貼る

詳細は packs/monitoring/README.md 参照
EOF
fi

echo "$SUCCESS_COUNT" > "$OUT_DIR/boris/_success_count"
echo "✓ saved to $OUT_DIR/boris/" >&2
