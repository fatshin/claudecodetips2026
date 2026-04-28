#!/usr/bin/env bash
# Claude Code公式docs / Anthropic公式ニュースをfetchしてsnapshot保存
# 使い方: bash scripts/fetch-docs.sh [output_dir]

set -euo pipefail

OUT_DIR="${1:-packs/monitoring/snapshots/$(date +%Y%m%d)}"
mkdir -p "$OUT_DIR"

# 監視対象URL（sources.yamlと同期）— bash 3.2互換（連想配列不使用）
URL_NAMES=(overview changelog hooks permissions subagents skills chrome checkpointing anthropic-news)
URL_VALS=(
  "https://code.claude.com/docs/en/overview"
  "https://code.claude.com/docs/en/changelog"
  "https://code.claude.com/docs/en/hooks"
  "https://code.claude.com/docs/en/permissions"
  "https://code.claude.com/docs/en/subagents"
  "https://code.claude.com/docs/en/skills"
  "https://code.claude.com/docs/en/chrome"
  "https://code.claude.com/docs/en/checkpointing"
  "https://www.anthropic.com/news"
)

mkdir -p "$OUT_DIR/docs"

for i in "${!URL_NAMES[@]}"; do
  name="${URL_NAMES[$i]}"
  url="${URL_VALS[$i]}"
  echo "→ $name : $url" >&2
  
  # curlで取得（HTML→text変換は別ツール推奨）
  if command -v lynx >/dev/null 2>&1; then
    # lynxでテキスト抽出（差分が読みやすい）
    lynx -dump -nolist "$url" > "$OUT_DIR/docs/$name.txt" 2>/dev/null || \
      echo "  ✗ $name 取得失敗" >&2
  elif command -v pandoc >/dev/null 2>&1; then
    # pandocでHTML→Markdown
    curl -s -L "$url" | pandoc -f html -t markdown -o "$OUT_DIR/docs/$name.md" 2>/dev/null || \
      echo "  ✗ $name 取得失敗" >&2
  else
    # 最低限curlだけ（HTMLをそのまま保存）
    curl -s -L "$url" -o "$OUT_DIR/docs/$name.html" || \
      echo "  ✗ $name 取得失敗" >&2
    # 簡易テキスト抽出（HTMLタグ除去）
    sed -e 's/<[^>]*>//g' \
        -e 's/&nbsp;/ /g' -e 's/&amp;/\&/g' \
        -e 's/&lt;/</g' -e 's/&gt;/>/g' \
        -e '/^[[:space:]]*$/d' \
        "$OUT_DIR/docs/$name.html" > "$OUT_DIR/docs/$name.txt" 2>/dev/null || true
  fi
  
  sleep 1  # rate limit回避
done

# メタ情報
cat > "$OUT_DIR/docs/_meta.json" <<EOF
{
  "fetched_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "tool": "$(if command -v lynx >/dev/null; then echo lynx; elif command -v pandoc >/dev/null; then echo pandoc; else echo curl-only; fi)",
  "urls": $(printf '%s\n' "${URL_NAMES[@]}" | jq -R . | jq -s .)
}
EOF

echo "" >&2
echo "✓ saved to $OUT_DIR/docs/" >&2
ls -la "$OUT_DIR/docs/" >&2
