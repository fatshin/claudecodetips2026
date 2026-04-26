#!/usr/bin/env bash
# fan-out: 1ファイルずつ claude -p に投げて並列移行する
# 使い方:
#   echo "src/old1.ts\nsrc/old2.ts" > files.txt
#   ./scripts/fanout.sh files.txt "Migrate from React class component to functional component with hooks"
#
# 安全策:
#   - 最初に5ファイルだけ -n で試行（失敗パターンを洗い出す）
#   - その後 -a で全量実行
#   - 並列数はデフォルト3。CPUとRate Limitと相談。

set -euo pipefail

usage() {
  cat <<EOF
使い方: $0 <files.txt> <prompt> [-n <試行数>] [-p <並列数>] [-a]
  files.txt   1行1ファイルパス
  prompt      Claudeへの指示
  -n N        最初のN件だけ実行（デフォルト5）
  -p N        並列数（デフォルト3）
  -a          全量実行
EOF
  exit 1
}

[ "$#" -lt 2 ] && usage
FILES="$1"; shift
PROMPT="$1"; shift

DRY_LIMIT=5
PARALLEL=3
ALL=0

while getopts "n:p:a" opt; do
  case $opt in
    n) DRY_LIMIT="$OPTARG" ;;
    p) PARALLEL="$OPTARG" ;;
    a) ALL=1 ;;
    *) usage ;;
  esac
done

[ ! -f "$FILES" ] && { echo "ファイル一覧 $FILES が見つからない"; exit 1; }

if [ "$ALL" -eq 0 ]; then
  echo "=== 試行モード: 最初の $DRY_LIMIT 件のみ実行 ==="
  TARGET="$(head -n "$DRY_LIMIT" "$FILES")"
else
  echo "=== 全量モード: $(wc -l < "$FILES") 件を並列度 $PARALLEL で実行 ==="
  TARGET="$(cat "$FILES")"
fi

LOG_DIR="./.claude/fanout-logs/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"

run_one() {
  local file="$1"
  local logfile="$LOG_DIR/$(echo "$file" | tr '/' '_').log"
  echo "[$(date +%H:%M:%S)] START: $file"
  if claude -p "$PROMPT for file: $file" \
      --output-format stream-json \
      --allowedTools "Read,Edit,Bash(git diff*),Bash(npm test*)" \
      > "$logfile" 2>&1; then
    echo "[$(date +%H:%M:%S)] DONE : $file → $logfile"
  else
    echo "[$(date +%H:%M:%S)] FAIL : $file → $logfile" >&2
    return 1
  fi
}

export -f run_one
export LOG_DIR PROMPT

if command -v parallel >/dev/null 2>&1; then
  echo "$TARGET" | parallel -j "$PARALLEL" run_one {}
else
  # parallel未インストール時の代替（xargs）
  echo "$TARGET" | xargs -I {} -P "$PARALLEL" bash -c 'run_one "$@"' _ {}
fi

echo ""
echo "=== 完了。ログ: $LOG_DIR ==="
echo "失敗件数: $(grep -l FAIL "$LOG_DIR"/*.log 2>/dev/null | wc -l)"
echo "git status で差分確認 → 問題なければまとめてコミット"
