#!/usr/bin/env bash
# 並列worktreeを起動するスクリプト
# 使い方:
#   ./scripts/worktree-spawn.sh feat/auth feat/billing fix/timeout
# → ../<repo>-feat-auth, ../<repo>-feat-billing, ../<repo>-fix-timeout を作って
#   それぞれで claude を別ターミナル（tmux/iTerm）で起動する

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "使い方: $0 <branch1> [branch2] [branch3] ..."
  echo "例: $0 feat/auth feat/billing fix/timeout"
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_ROOT")"
PARENT_DIR="$(dirname "$REPO_ROOT")"

if [ "$#" -gt 5 ]; then
  echo "警告: 並列数 $# はBoris推奨の3〜5を超える。レビュー帯域とCPUに注意。"
fi

USE_TMUX=0
if command -v tmux >/dev/null 2>&1; then
  USE_TMUX=1
  SESSION="cc-$(date +%s)"
  tmux new-session -d -s "$SESSION" -c "$REPO_ROOT"
fi

INDEX=0
for BRANCH in "$@"; do
  INDEX=$((INDEX + 1))
  SAFE_BRANCH="${BRANCH//\//-}"
  WT_PATH="$PARENT_DIR/${REPO_NAME}-${SAFE_BRANCH}"

  if [ -d "$WT_PATH" ]; then
    echo "✓ worktreeすでに存在: $WT_PATH"
  else
    echo "+ 作成: $WT_PATH (branch: $BRANCH)"
    git worktree add "$WT_PATH" -b "$BRANCH" 2>/dev/null \
      || git worktree add "$WT_PATH" "$BRANCH"
  fi

  ESCAPED_PATH="$(printf '%q' "$WT_PATH")"
  if [ "$USE_TMUX" -eq 1 ]; then
    if [ "$INDEX" -eq 1 ]; then
      tmux send-keys -t "$SESSION" "cd ${ESCAPED_PATH} && claude" C-m
    else
      tmux split-window -t "$SESSION" -c "$WT_PATH"
      tmux send-keys -t "$SESSION" "claude" C-m
      tmux select-layout -t "$SESSION" tiled
    fi
  else
    echo "  起動コマンド: cd ${ESCAPED_PATH} && claude"
  fi
done

if [ "$USE_TMUX" -eq 1 ]; then
  echo ""
  echo "tmuxセッション '$SESSION' で $# 個のworktreeを起動"
  echo "アタッチ: tmux attach -t $SESSION"
  echo "停止: tmux kill-session -t $SESSION"
fi

echo ""
echo "現在のworktree一覧:"
git worktree list
