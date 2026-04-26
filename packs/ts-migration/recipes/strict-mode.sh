#!/usr/bin/env bash
# tsconfig strict段階有効化
# 一気にstrict: trueにすると地獄。1フラグずつ有効化して修正する戦略。

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# strictフラグの有効化順（影響度の小さい順）
FLAGS=(
  "noImplicitThis"
  "alwaysStrict"
  "strictBindCallApply"
  "noImplicitAny"
  "strictNullChecks"
  "strictFunctionTypes"
  "strictPropertyInitialization"
)

usage() {
  cat <<EOF
使い方: $0 <flag-name>
有効化対象フラグ:
$(for f in "${FLAGS[@]}"; do echo "  - $f"; done)

または: $0 --next   （最初の未有効フラグを処理）
EOF
  exit 1
}

[ "$#" -lt 1 ] && usage

if [ "$1" = "--next" ]; then
  TSCONFIG="$(find . -maxdepth 2 -name 'tsconfig.json' -not -path './node_modules/*' | head -1)"
  for f in "${FLAGS[@]}"; do
    if ! grep -q "\"$f\":\\s*true" "$TSCONFIG"; then
      TARGET_FLAG="$f"
      break
    fi
  done
  [ -z "${TARGET_FLAG:-}" ] && { echo "全フラグ既に有効。完了。"; exit 0; }
else
  TARGET_FLAG="$1"
fi

echo "=== $TARGET_FLAG を有効化 ==="

# Step 1: tsconfig.jsonに追加
node -e "
const fs = require('fs');
const path = 'tsconfig.json';
const cfg = JSON.parse(fs.readFileSync(path, 'utf8'));
cfg.compilerOptions = cfg.compilerOptions || {};
cfg.compilerOptions['$TARGET_FLAG'] = true;
fs.writeFileSync(path, JSON.stringify(cfg, null, 2));
"

# Step 2: type checkで失敗するファイルを抽出
ERROR_LOG="$(mktemp)"
trap "rm -f $ERROR_LOG ${ERROR_LOG}.files" EXIT

npx tsc --noEmit 2>&1 | tee "$ERROR_LOG" || true

# エラーが出たファイルを重複なく抽出
grep -oE '^[^(]+\.(ts|tsx)' "$ERROR_LOG" | sort -u > "${ERROR_LOG}.files" || true
ERR_FILES_COUNT="$(wc -l < "${ERROR_LOG}.files")"

if [ "$ERR_FILES_COUNT" -eq 0 ]; then
  echo "✓ $TARGET_FLAG 有効化でエラー無し。コミット可能。"
  exit 0
fi

echo "✗ $ERR_FILES_COUNT ファイルでエラー。fan-outで修正開始。"

# Step 3: fan-outで修正
PROMPT="tsconfig.json で $TARGET_FLAG: true を有効化したらこのファイルでTypeScriptエラーが出た。
以下の方針で修正せよ:

1. 型注釈を追加（any型は最終手段、まずは適切な型を考える）
2. nullableが必要なら明示的に `T | null` または `T | undefined`
3. オプショナルチェイニング `?.` を活用
4. non-null assertion `!` は最終手段（コメントで根拠を残す）
5. 動作を変えるリファクタは禁止。型エラー解消のみ
6. 不明な箇所は `// FIXME($TARGET_FLAG): ` コメントで残してanyで一旦逃げる

エラー箇所はnpx tscの出力で確認できる。修正後のコードのみ出力。

ファイル: "

exec bash "$(git rev-parse --show-toplevel)/scripts/fanout.sh" \
  "${ERROR_LOG}.files" \
  "$PROMPT" \
  -p 3
