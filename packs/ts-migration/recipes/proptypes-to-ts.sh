#!/usr/bin/env bash
# PropTypes → TypeScript型 完全移行
# - propTypesプロパティを削除
# - interface XXXProps を生成
# - prop-typesのimportを削除
# - package.jsonからprop-typesを除去

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PATTERN="${PATTERN:-src}"
MODE="dry"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --all) MODE="all"; shift ;;
    --pattern) PATTERN="$2"; shift 2 ;;
    *) shift ;;
  esac
done

FILES_TXT="$(mktemp)"
trap "rm -f $FILES_TXT ${FILES_TXT}.*" EXIT

rg -l '(import.*prop-types|propTypes\s*[:=]|PropTypes\.)' \
   --type ts --type tsx --type js --type jsx \
   "$PATTERN" > "$FILES_TXT" || true

TOTAL="$(wc -l < "$FILES_TXT")"
echo "対象: $TOTAL ファイル"

[ "$TOTAL" -eq 0 ] && { echo "PropTypes使用無し。完了。"; exit 0; }

if [ "$MODE" = "dry" ]; then
  head -n 5 "$FILES_TXT" > "${FILES_TXT}.target"
else
  cp "$FILES_TXT" "${FILES_TXT}.target"
fi

PROMPT='以下のファイルからPropTypesを削除してTypeScript型に変換せよ。

変換マッピング:
- PropTypes.string                → string
- PropTypes.string.isRequired     → string (オプショナル時 string | undefined)
- PropTypes.number                → number
- PropTypes.bool                  → boolean
- PropTypes.func                  → (...args: any[]) => any （シグネチャわかれば具体化）
- PropTypes.array                 → unknown[] （要素型わかれば具体化）
- PropTypes.object                → Record<string, unknown>
- PropTypes.shape({...})          → { ... } interface
- PropTypes.oneOf([...])          → リテラル型 union
- PropTypes.oneOfType([...])      → union型
- PropTypes.arrayOf(X)            → X[]
- PropTypes.objectOf(X)           → Record<string, X>
- PropTypes.node                  → React.ReactNode
- PropTypes.element               → React.ReactElement
- PropTypes.elementType           → React.ElementType
- PropTypes.instanceOf(X)         → X
- PropTypes.any                   → unknown

実施事項:
1. import { ... } from "prop-types" を削除
2. ComponentName.propTypes = { ... } を削除
3. interface ComponentNameProps を生成（無ければ）
4. 関数コンポーネント引数に Props型を適用
5. defaultProps が残ってたら関数引数のデフォルト値に移行

注意:
- 動作は変えない（型注釈追加のみ）
- 既にinterface定義があれば既存と統合
- 元のJSDocコメントは保持

変換後のコードのみ出力。

ファイル: '

exec bash "$(git rev-parse --show-toplevel)/scripts/fanout.sh" \
  "${FILES_TXT}.target" \
  "$PROMPT" \
  ${MODE:+-a}
