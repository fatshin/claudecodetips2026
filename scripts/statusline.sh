#!/usr/bin/env bash
# Claude Codeのstatus line表示スクリプト
# stdin から JSON を受け取り、1行で状態を出力する。
# 公式仕様: https://code.claude.com/docs/en/statusline

set -euo pipefail

INPUT="$(cat)"

# 各種抽出（jqがあれば使う、なければgrep+sed）
extract() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r "$key // \"\""
  else
    printf '%s' "$INPUT" | grep -oE "\"${key#.}\":[^,}]*" | head -n1 | sed 's/.*://;s/[\"]//g' || echo ""
  fi
}

MODEL="$(extract '.model.display_name')"
CWD="$(extract '.workspace.current_dir')"
COST_USD="$(extract '.cost.total_cost_usd')"

# git branch（cwd配下から）
BRANCH=""
if [ -n "$CWD" ] && [ -d "$CWD/.git" ]; then
  BRANCH="$(cd "$CWD" && git branch --show-current 2>/dev/null || echo "")"
elif [ -d ".git" ]; then
  BRANCH="$(git branch --show-current 2>/dev/null || echo "")"
fi

# context使用率（環境変数CLAUDE_CONTEXT_USED_PCTがあれば使用、なければ未表示）
CTX="${CLAUDE_CONTEXT_USED_PCT:-}"

# 表示フォーマット: [model] branch | ctx:XX% | $0.0123
OUT=""
[ -n "$MODEL" ]    && OUT="$OUT[$MODEL] "
[ -n "$BRANCH" ]   && OUT="$OUT⎇ $BRANCH "
[ -n "$CTX" ]      && OUT="$OUT| ctx:${CTX}% "
[ -n "$COST_USD" ] && OUT="$OUT| \$${COST_USD}"

printf '%s\n' "$OUT"
