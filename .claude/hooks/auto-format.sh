#!/usr/bin/env bash
# PostToolUse hook: ファイル編集後に言語別フォーマッタを自動実行。
# JSON入力を stdin から受け取る。
set -euo pipefail

INPUT="$(cat)"
if ! command -v jq >/dev/null 2>&1; then
  FILE_PATH="$(printf '%s' "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)"
  [ -z "$FILE_PATH" ] && FILE_PATH="$(printf '%s' "$INPUT" | grep -o '"path":"[^"]*"' | head -1 | cut -d'"' -f4)"
else
  FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')"
fi

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.md|*.css|*.html|*.yaml|*.yml)
    if command -v prettier >/dev/null 2>&1; then
      prettier --write --log-level warn "$FILE_PATH" 2>/dev/null || true
    elif command -v npx >/dev/null 2>&1; then
      npx --yes --no-install prettier --write --log-level warn "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$FILE_PATH" 2>/dev/null || true
      ruff check --fix --quiet "$FILE_PATH" 2>/dev/null || true
    elif command -v black >/dev/null 2>&1; then
      black --quiet "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$FILE_PATH" 2>/dev/null || true
    ;;
  *.rs)
    command -v rustfmt >/dev/null 2>&1 && rustfmt --quiet "$FILE_PATH" 2>/dev/null || true
    ;;
  *.sh|*.bash)
    command -v shfmt >/dev/null 2>&1 && shfmt -w "$FILE_PATH" 2>/dev/null || true
    ;;
esac

exit 0
