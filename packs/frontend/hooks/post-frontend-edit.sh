#!/usr/bin/env bash
# PostToolUse hook: フロントエンドファイル編集後に自動チェック
# 注意: 編集毎に走るとビルド時間・コストがかさむので慎重に。
#       本格運用は CI（PR時）に寄せて、ローカルhookは最小限に。
#
# .claude/settings.json への登録例（オプトイン）:
#   "PostToolUse": [
#     {
#       "matcher": "Edit|Write",
#       "hooks": [
#         { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-frontend-edit.sh", "timeout": 60 }
#       ]
#     }
#   ]

set -euo pipefail

INPUT="$(cat)"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")"

[ -z "$FILE_PATH" ] && exit 0

# 対象拡張子
case "$FILE_PATH" in
  *.tsx|*.jsx|*.vue|*.svelte|*.html|*.css|*.scss)
    :  # 対象 → 続行
    ;;
  *)
    exit 0
    ;;
esac

# heavy check は環境変数で明示有効化（デフォルトoff）
[ "${CLAUDE_HOOK_FRONTEND_HEAVY:-0}" != "1" ] && exit 0

# dev server起動チェック（無ければスキップ）
DEV_URL="${DEV_URL:-http://localhost:3000}"
if ! curl -s -o /dev/null -m 2 "$DEV_URL"; then
  exit 0
fi

# 軽量a11yチェック（タイムアウト短め）
echo "[hook] 軽量a11yチェック実行中..." >&2
timeout 30 bash "$CLAUDE_PROJECT_DIR/scripts/axe-check.sh" "$DEV_URL" wcag21aa json 2>/dev/null \
  | tail -5 >&2 || echo "[hook] a11yチェック skip/失敗" >&2

exit 0
