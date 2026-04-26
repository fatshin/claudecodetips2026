#!/usr/bin/env bash
# Claude Code Kit パック選択導入
#
# 使い方:
#   bash scripts/install-packs.sh --all
#   bash scripts/install-packs.sh --packs advisors,multi-llm
#   bash scripts/install-packs.sh --packs mcp,path-claude

set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${TARGET:-$PWD}"
PACKS_DIR="$KIT_DIR/packs"

ALL_PACKS=("mcp" "path-claude" "ts-migration" "github-actions" "multi-llm" "advisors" "research-preview" "frontend" "monitoring")

usage() {
  cat <<EOF
使い方: $0 [options]

  --all                    全パック導入
  --packs <p1,p2,...>      指定パックのみ導入
  --target <dir>           対象ディレクトリ（デフォルト: $PWD）
  --list                   利用可能パック一覧
  --help                   このヘルプ

利用可能パック:
  - mcp               : Dify/Bedrock/GitHub/Slack MCP連携
  - path-claude       : サブディレクトリ別CLAUDE.md
  - ts-migration      : TypeScript移行レシピ
  - github-actions    : Issue→PR自動化、multi-LLM review
  - multi-llm         : Gemini/Codex並走 (gemini/codex CLI必要)
  - advisors          : principal/security/cost/product
  - research-preview  : /ultrareview, /ultraplan等 (advisors+multi-llm前提)
  - frontend          : Chrome拡張+Lighthouse+axe+e2e (Playwright必要)
  - monitoring        : Boris/公式docs/releases監視→自動提案 (gh+lynx必要)

依存関係:
  research-preview → advisors + multi-llm
  monitoring → claude CLI （任意でgemini CLI）
EOF
}

[ "$#" -eq 0 ] && { usage; exit 1; }

SELECTED_PACKS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --all)
      SELECTED_PACKS=("${ALL_PACKS[@]}")
      shift
      ;;
    --packs)
      IFS=',' read -ra SELECTED_PACKS <<< "$2"
      shift 2
      ;;
    --target)
      TARGET="$2"
      shift 2
      ;;
    --list)
      echo "利用可能パック:"
      for p in "${ALL_PACKS[@]}"; do echo "  - $p"; done
      exit 0
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "不明なオプション: $1"
      usage
      exit 1
      ;;
  esac
done

[ ! -d "$TARGET/.git" ] && { echo "✗ $TARGET はgitリポジトリではない"; exit 1; }
[ ! -d "$TARGET/.claude" ] && { echo "✗ .claudeディレクトリ無し。先に install.sh を実行を。"; exit 1; }

# 依存解決: research-preview → advisors + multi-llm
for p in "${SELECTED_PACKS[@]}"; do
  if [ "$p" = "research-preview" ]; then
    if [[ ! " ${SELECTED_PACKS[*]} " =~ " advisors " ]]; then
      echo "ℹ research-preview は advisors を要求するため自動追加"
      SELECTED_PACKS+=("advisors")
    fi
    if [[ ! " ${SELECTED_PACKS[*]} " =~ " multi-llm " ]]; then
      echo "ℹ research-preview は multi-llm を要求するため自動追加"
      SELECTED_PACKS+=("multi-llm")
    fi
  fi
done

echo "=== 導入対象 ==="
for p in "${SELECTED_PACKS[@]}"; do echo "  - $p"; done
echo ""

install_pack_mcp() {
  echo "→ MCP導入"
  if [ -f "$TARGET/.mcp.json" ]; then
    echo "  既存の.mcp.jsonがある。.mcp.json.kit-example として配置"
    cp "$PACKS_DIR/mcp/mcp.json" "$TARGET/.mcp.json.kit-example"
  else
    cp "$PACKS_DIR/mcp/mcp.json" "$TARGET/.mcp.json"
  fi
  [ ! -f "$TARGET/.env.local" ] && cp "$PACKS_DIR/mcp/.env.example" "$TARGET/.env.local"
  grep -qxF '.env.local' "$TARGET/.gitignore" 2>/dev/null || echo '.env.local' >> "$TARGET/.gitignore"
  cp "$PACKS_DIR/mcp/README.md" "$TARGET/.claude/MCP-README.md"
  echo "  ✓ .mcp.json + .env.local + .claude/MCP-README.md"
}

install_pack_path_claude() {
  echo "→ path-claude導入（テンプレを .claude/path-claude-templates/ へ）"
  mkdir -p "$TARGET/.claude/path-claude-templates"
  cp "$PACKS_DIR/path-claude"/*.md "$TARGET/.claude/path-claude-templates/"
  echo "  ✓ テンプレを配置。手動で各ディレクトリへコピーすること:"
  echo "    cp .claude/path-claude-templates/src-billing-CLAUDE.md src/billing/CLAUDE.md"
}

install_pack_ts_migration() {
  echo "→ ts-migration導入"
  mkdir -p "$TARGET/recipes"
  cp "$PACKS_DIR/ts-migration/recipes"/*.sh "$TARGET/recipes/"
  chmod +x "$TARGET/recipes"/*.sh
  cp "$PACKS_DIR/ts-migration/README.md" "$TARGET/recipes/README.md"
  echo "  ✓ recipes/*.sh"
}

install_pack_github_actions() {
  echo "→ github-actions導入"
  mkdir -p "$TARGET/.github/workflows"
  for f in "$PACKS_DIR/github-actions"/*.yml; do
    name="$(basename "$f")"
    if [ ! -f "$TARGET/.github/workflows/$name" ]; then
      cp "$f" "$TARGET/.github/workflows/$name"
      echo "  ✓ .github/workflows/$name"
    else
      echo "  ⚠ .github/workflows/$name は既存。.kit-example として配置"
      cp "$f" "$TARGET/.github/workflows/$name.kit-example"
    fi
  done
}

install_pack_multi_llm() {
  echo "→ multi-llm導入"
  cp "$PACKS_DIR/multi-llm/agents"/*.md   "$TARGET/.claude/agents/"
  cp "$PACKS_DIR/multi-llm/commands"/*.md "$TARGET/.claude/commands/"
  mkdir -p "$TARGET/scripts"
  cp "$PACKS_DIR/multi-llm/scripts"/*.sh  "$TARGET/scripts/"
  chmod +x "$TARGET/scripts"/cross-review.sh
  echo "  ✓ agents + commands + scripts"
  echo "  ⚠ gemini-cli, codex CLI のインストール必要:"
  echo "    npm install -g @google/gemini-cli @openai/codex"
}

install_pack_advisors() {
  echo "→ advisors導入"
  cp "$PACKS_DIR/advisors/agents"/*.md   "$TARGET/.claude/agents/"
  cp "$PACKS_DIR/advisors/commands"/*.md "$TARGET/.claude/commands/"
  echo "  ✓ 4 advisors + 3 commands (/advise, /arch-review, /pre-mortem)"
}

install_pack_research_preview() {
  echo "→ research-preview導入"
  cp "$PACKS_DIR/research-preview/commands"/*.md "$TARGET/.claude/commands/"
  mkdir -p "$TARGET/.github/workflows"
  for f in "$PACKS_DIR/research-preview/workflows"/*.yml; do
    name="$(basename "$f")"
    if [ ! -f "$TARGET/.github/workflows/$name" ]; then
      cp "$f" "$TARGET/.github/workflows/$name"
    else
      cp "$f" "$TARGET/.github/workflows/$name.kit-example"
    fi
  done
  # BTW-PATTERNS.md を docs/ に
  mkdir -p "$TARGET/docs"
  cp "$PACKS_DIR/research-preview/BTW-PATTERNS.md" "$TARGET/docs/"
  # Issue templateも配置
  mkdir -p "$TARGET/.github/ISSUE_TEMPLATE"
  cp "$KIT_DIR/.github/ISSUE_TEMPLATE/research-preview-watch.md" \
     "$TARGET/.github/ISSUE_TEMPLATE/" 2>/dev/null || true
  echo "  ✓ /ultrareview /ultraplan /simplify /schedule + workflows + BTW-PATTERNS.md"
}

install_pack_frontend() {
  echo "→ frontend導入"
  cp "$PACKS_DIR/frontend/agents"/*.md       "$TARGET/.claude/agents/"
  cp -r "$PACKS_DIR/frontend/skills"/*       "$TARGET/.claude/skills/"
  cp "$PACKS_DIR/frontend/commands"/*.md     "$TARGET/.claude/commands/"
  mkdir -p "$TARGET/scripts"
  cp "$PACKS_DIR/frontend/scripts"/*.sh      "$TARGET/scripts/"
  chmod +x "$TARGET/scripts"/{screenshot,lighthouse-check,axe-check,e2e-smoke}.sh 2>/dev/null || true
  mkdir -p "$TARGET/.claude/hooks"
  cp "$PACKS_DIR/frontend/hooks"/*.sh        "$TARGET/.claude/hooks/"
  chmod +x "$TARGET/.claude/hooks/post-frontend-edit.sh" 2>/dev/null || true
  mkdir -p "$TARGET/docs"
  cp "$PACKS_DIR/frontend/CHROME-EXTENSION-SETUP.md" "$TARGET/docs/"
  echo "  ✓ frontend-qa subagent + 3 skills + 4 commands + scripts"
  echo "  ⚠ npm install -g lighthouse @axe-core/cli playwright"
  echo "    npx playwright install chromium"
}

install_pack_monitoring() {
  echo "→ monitoring導入"
  # packs/monitoring 一式を target にコピー
  mkdir -p "$TARGET/packs/monitoring"
  cp -r "$PACKS_DIR/monitoring"/* "$TARGET/packs/monitoring/" 2>/dev/null || true
  chmod +x "$TARGET/packs/monitoring/scripts"/*.sh 2>/dev/null || true
  
  # commands と workflow を所定位置に
  cp "$PACKS_DIR/monitoring/commands"/*.md "$TARGET/.claude/commands/"
  mkdir -p "$TARGET/.github/workflows"
  if [ ! -f "$TARGET/.github/workflows/monitor-update.yml" ]; then
    cp "$PACKS_DIR/monitoring/workflows/monitor-update.yml" "$TARGET/.github/workflows/"
  else
    cp "$PACKS_DIR/monitoring/workflows/monitor-update.yml" "$TARGET/.github/workflows/monitor-update.yml.kit-example"
  fi
  
  # 手動投入テンプレ配置
  mkdir -p "$TARGET/docs"
  if [ ! -f "$TARGET/docs/manual-boris-input.md" ]; then
    cp "$PACKS_DIR/monitoring/manual-boris-input.md.example" \
       "$TARGET/docs/manual-boris-input.md"
  fi
  
  # snapshots ディレクトリは git管理（_diffだけ除外）
  mkdir -p "$TARGET/packs/monitoring/snapshots"
  touch "$TARGET/packs/monitoring/snapshots/.gitkeep"
  
  # .gitignore追記
  GITIGNORE="$TARGET/.gitignore"
  for line in "packs/monitoring/snapshots/*/_diff/" "packs/monitoring/snapshots/*/*.html"; do
    grep -qxF "$line" "$GITIGNORE" 2>/dev/null || echo "$line" >> "$GITIGNORE"
  done
  
  echo "  ✓ monitoring scripts + workflow + /check-updates command"
  echo "  ⚠ 必須ツール: gh, jq, lynx (or pandoc)"
  echo "  ⚠ APIキー: ANTHROPIC_API_KEY, GEMINI_API_KEY (任意)"
}

# 各pack実行
for p in "${SELECTED_PACKS[@]}"; do
  case "$p" in
    mcp) install_pack_mcp ;;
    path-claude) install_pack_path_claude ;;
    ts-migration) install_pack_ts_migration ;;
    github-actions) install_pack_github_actions ;;
    multi-llm) install_pack_multi_llm ;;
    advisors) install_pack_advisors ;;
    research-preview) install_pack_research_preview ;;
    frontend) install_pack_frontend ;;
    monitoring) install_pack_monitoring ;;
    *) echo "✗ 不明なpack: $p"; exit 1 ;;
  esac
done

echo ""
echo "=== 完了 ==="
echo ""
echo "次のアクション:"
echo "  1. APIキー設定（必要なpackに応じて）"
echo "     export ANTHROPIC_API_KEY='sk-ant-xxx'"
[[ " ${SELECTED_PACKS[*]} " =~ " multi-llm " ]] && \
  echo "     export GEMINI_API_KEY='AIzaSy-xxx'  # multi-llm用"
[[ " ${SELECTED_PACKS[*]} " =~ " multi-llm " ]] && \
  echo "     export OPENAI_API_KEY='sk-xxx'  # multi-llm用"
[[ " ${SELECTED_PACKS[*]} " =~ " mcp " ]] && \
  echo "  2. .env.local を編集して各MCPの認証情報を入れる"
echo "  3. claude を起動して /agents /mcp で読込確認"
echo ""
echo "各packの詳細: cat $PACKS_DIR/<pack-name>/README.md"
