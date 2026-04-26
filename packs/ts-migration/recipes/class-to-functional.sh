#!/usr/bin/env bash
# React Class Component → Functional Component (with Hooks) 移行
# 使い方:
#   ./recipes/class-to-functional.sh                # 試行（先頭5件）
#   ./recipes/class-to-functional.sh --all          # 全量
#   ./recipes/class-to-functional.sh --pattern X    # パターン絞込

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PATTERN="${PATTERN:-src/components}"
MODE="dry"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --all) MODE="all"; shift ;;
    --pattern) PATTERN="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Class componentを含むファイルを抽出
FILES_TXT="$(mktemp)"
trap "rm -f $FILES_TXT" EXIT

rg -l 'extends\s+(React\.)?(Component|PureComponent)' \
   --type ts --type tsx \
   "$PATTERN" > "$FILES_TXT" || true

TOTAL="$(wc -l < "$FILES_TXT")"
echo "対象: $TOTAL ファイル"

if [ "$TOTAL" -eq 0 ]; then
  echo "Class componentが見つからない。完了。"
  exit 0
fi

if [ "$MODE" = "dry" ]; then
  echo "=== 試行モード（先頭5件） ==="
  head -n 5 "$FILES_TXT" > "${FILES_TXT}.target"
else
  echo "=== 全量モード（$TOTAL 件） ==="
  cp "$FILES_TXT" "${FILES_TXT}.target"
fi

PROMPT='以下のReactクラスコンポーネントを関数コンポーネント（hooks）に変換せよ。要件:

1. constructor → useState初期化
2. componentDidMount → useEffect(..., [])
3. componentDidUpdate → useEffect(..., [deps])
4. componentWillUnmount → useEffect cleanup return
5. setState → 個別のuseStateまたはuseReducer
6. ref → useRef
7. context → useContext
8. propsの型はそのまま維持。必要ならinterface名を `<Name>Props` に統一
9. defaultProps → 関数引数のデフォルト値
10. PropTypes → TypeScript型のみで表現（PropTypesは削除）

変換後のコードのみ出力。コメントで変換意図を残さない。
変換不能（複雑なライフサイクル等）なら "// MIGRATION_SKIP: <理由>" を最初の行に追加して元のコードを残す。

ファイル: '

# fanout.shを使って並列処理
exec bash "$(git rev-parse --show-toplevel)/scripts/fanout.sh" \
  "${FILES_TXT}.target" \
  "$PROMPT" \
  ${MODE:+-a}
