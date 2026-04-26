#!/usr/bin/env bash
# Claude Code公式docs / Anthropic公式ニュースをfetchしてsnapshot保存
# 使い方: bash scripts/fetch-docs.sh [output_dir]

set -euo pipefail

OUT_DIR="${1:-packs/monitoring/snapshots/$(date +%Y%m%d)}"
mkdir -p "$OUT_DIR"

# 監視対象URL（sources.yamlと同期）
declare -A URLS=(
  [overview]="https://code.claude.com/docs/en/overview"
  [changelog]="https://code.claude.com/docs/en/changelog"
  [hooks]="https://code.claude.com/docs/en/hooks"
  [permissions]="https://code.claude.com/docs/en/permissions"
  [subagents]="https://code.claude.com/docs/en/subagents"
  [skills]="https://code.claude.com/docs/en/skills"
  [chrome]="https://code.claude.com/docs/en/chrome"
  [checkpointing]="https://code.claude.com/docs/en/checkpointing"
  [anthropic-news]="https://www.anthropic.com/news"
)

mkdir -p "$OUT_DIR/docs"

for name in "${!URLS[@]}"; do
  url="${URLS[$name]}"
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
  "urls": $(printf '%s\n' "${!URLS[@]}" | jq -R . | jq -s .)
}
EOF

echo "" >&2
echo "✓ saved to $OUT_DIR/docs/" >&2
ls -la "$OUT_DIR/docs/" >&2
