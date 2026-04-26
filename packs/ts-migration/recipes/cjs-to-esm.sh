#!/usr/bin/env bash
# CommonJS → ES Modules 移行
# require/module.exports → import/export

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

# require/module.exportsを含むTS/JSファイル
rg -l '(require\(|module\.exports|exports\.[a-zA-Z])' \
   --type ts --type js \
   "$PATTERN" > "$FILES_TXT" || true

TOTAL="$(wc -l < "$FILES_TXT")"
echo "対象: $TOTAL ファイル"

[ "$TOTAL" -eq 0 ] && { echo "CommonJSパターン無し。完了。"; exit 0; }

if [ "$MODE" = "dry" ]; then
  head -n 5 "$FILES_TXT" > "${FILES_TXT}.target"
else
  cp "$FILES_TXT" "${FILES_TXT}.target"
fi

PROMPT='以下のCommonJSコードをES Modulesに変換せよ。

変換ルール:
- const x = require("y")           → import x from "y"
- const { a, b } = require("y")    → import { a, b } from "y"
- const x = require("y").default   → import x from "y"
- module.exports = x               → export default x
- module.exports.a = a             → export const a = a (または export { a })
- exports.a = a                    → export const a (または export { a })
- 動的require → 一旦 // FIXME_DYNAMIC_IMPORT コメント追加
- __dirname / __filename → import.meta.url 経由で再現

注意:
- import文はファイル先頭に集約。中間importは禁止
- 拡張子は .js または .ts を明示（"./foo" → "./foo.js" 等）。tsconfig.json次第で調整
- type-only importは `import type { ... }` を使う
- circular依存があれば "// MIGRATION_WARN: circular" コメント残す

変換後のコードのみ出力。説明不要。

ファイル: '

exec bash "$(git rev-parse --show-toplevel)/scripts/fanout.sh" \
  "${FILES_TXT}.target" \
  "$PROMPT" \
  ${MODE:+-a}
