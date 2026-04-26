#!/usr/bin/env bash
# Claude Code Kit セットアップスクリプト
# 既存リポジトリのルートで実行する。

set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-$PWD}"

if [ ! -d "$TARGET/.git" ]; then
  echo "✗ $TARGET はgitリポジトリではない。リポジトリのルートで実行を。"
  exit 1
fi

echo "=== Claude Code Kit を $TARGET にセットアップ ==="

# 1. .claudeディレクトリのコピー（既存ファイルは上書き確認）
if [ -d "$TARGET/.claude" ]; then
  read -rp "既存の .claude/ がある。バックアップして上書きする？(y/N) " ans
  [ "$ans" != "y" ] && { echo "中止"; exit 0; }
  mv "$TARGET/.claude" "$TARGET/.claude.bak.$(date +%s)"
fi

cp -r "$KIT_DIR/.claude" "$TARGET/.claude"
chmod +x "$TARGET/.claude/hooks/"*.sh "$TARGET/.claude/hooks/"*.py 2>/dev/null || true

# 2. CLAUDE.md（既存があれば名前変えて保存、新規はテンプレ配置）
if [ -f "$TARGET/CLAUDE.md" ]; then
  echo "✓ 既存のCLAUDE.mdを保持。テンプレは CLAUDE.md.template として配置"
  cp "$KIT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md.template"
else
  cp "$KIT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
fi

# 3. scripts/ をコピー
mkdir -p "$TARGET/scripts"
cp "$KIT_DIR/scripts/"*.sh "$TARGET/scripts/"
chmod +x "$TARGET/scripts/"*.sh

# 4. GitHub Actionsをコピー（既存workflowsは触らない）
mkdir -p "$TARGET/.github/workflows"
if [ ! -f "$TARGET/.github/workflows/claude-pr.yml" ]; then
  cp "$KIT_DIR/.github/workflows/claude-pr.yml" "$TARGET/.github/workflows/"
fi

# 5. .gitignoreに追記（重複は避ける）
GITIGNORE="$TARGET/.gitignore"
touch "$GITIGNORE"
for line in ".claude/settings.local.json" ".claude/fanout-logs/" ".claude/memory/"; do
  if ! grep -qxF "$line" "$GITIGNORE"; then
    echo "$line" >> "$GITIGNORE"
  fi
done

# 6. settings.local.jsonの雛形配置（コミット対象外）
[ ! -f "$TARGET/.claude/settings.local.json" ] && \
  cp "$KIT_DIR/.claude/settings.local.json.example" "$TARGET/.claude/settings.local.json"

echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "次のアクション:"
echo "  1. CLAUDE.md を編集（プロジェクト固有の規約・コマンドを追記）"
echo "  2. .claude/settings.json の permissions をプロジェクトに合わせ調整"
echo "  3. 機密ファイル保護を確認: chmod +x .claude/hooks/protect-secrets.py"
echo "  4. claude を起動して /permissions で読み込みを確認"
echo "  5. Anthropic API key を GitHub Secrets に登録（GitHub Action用）"
echo ""
echo "ドキュメント: $TARGET/.claude/README.md（あれば）"
