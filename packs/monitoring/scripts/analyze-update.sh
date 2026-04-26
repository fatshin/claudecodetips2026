#!/usr/bin/env bash
# 差分をClaudeに分析させてアップデート提案レポートを作成
# 使い方: bash scripts/analyze-update.sh <diff_dir> [output.md]

set -euo pipefail

DIFF_DIR="${1:?diff ディレクトリ指定}"
OUTPUT="${2:-$DIFF_DIR/update-proposal.md}"

if [ ! -d "$DIFF_DIR" ]; then
  echo "✗ $DIFF_DIR が存在しない" >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "✗ claude CLI が必要" >&2
  exit 1
fi

# === 入力データ集約 ===
INPUT_FILE="$(mktemp)"
trap "rm -f $INPUT_FILE" EXIT

{
  echo "# Claude Code Kit Update Analysis"
  echo ""
  echo "## サマリー"
  if [ -f "$DIFF_DIR/_summary.json" ]; then
    cat "$DIFF_DIR/_summary.json"
  fi
  echo ""
  
  # === GitHub releases ===
  if [ -s "$DIFF_DIR/new-releases.json" ]; then
    NEW_COUNT=$(jq 'length' "$DIFF_DIR/new-releases.json")
    if [ "$NEW_COUNT" -gt 0 ]; then
      echo "## 新規GitHub releases ($NEW_COUNT件)"
      jq -r '.[] | "### " + .tagName + " (" + (.publishedAt // "?") + ")\n" + (.name // "") + "\n\n" + (.body // "") + "\n---\n"' \
        "$DIFF_DIR/new-releases.json"
      echo ""
    fi
  fi
  
  # === 公式docs変更 ===
  if [ -d "$DIFF_DIR/docs" ] && ls "$DIFF_DIR/docs"/*.diff >/dev/null 2>&1; then
    echo "## 公式docs変更"
    for diff_file in "$DIFF_DIR/docs"/*.diff; do
      name="$(basename "$diff_file" .diff)"
      echo "### docs: $name"
      echo '```diff'
      head -200 "$diff_file"  # 大きい差分は最初の200行のみ
      echo '```'
      echo ""
    done
  fi
  
  # === Boris発信 ===
  if [ -d "$DIFF_DIR/boris" ] && [ "$(ls -A "$DIFF_DIR/boris" 2>/dev/null)" ]; then
    echo "## Boris Cherny 発信"
    for f in "$DIFF_DIR/boris"/*; do
      [ -f "$f" ] || continue
      echo "### $(basename "$f")"
      echo '```'
      head -100 "$f"
      echo '```'
      echo ""
    done
  fi
} > "$INPUT_FILE"

INPUT_SIZE=$(wc -l < "$INPUT_FILE")
echo "=== 入力サイズ: $INPUT_SIZE 行 ===" >&2

# === Claudeで分析 ===
PROMPT='上記は Claude Code 関連ソース（公式docs、GitHub releases、Boris Cherny発信）の最新変更diff。

このKitに対するアップデート提案を以下のフォーマットで出力せよ:

# Claude Code Kit アップデート提案

## エグゼクティブサマリー
- 検知された主要変化（最重要3件）
- このKitへの影響度: 高/中/低
- 推奨対応タイミング: 即時/今四半期/様子見

## 機能別影響分析

### 新機能の検知
| 新機能 | ソース | 状態 (GA/Beta/Preview) | このKitとの関係 |
|---|---|---|---|

### 既存機能の変更
| 機能 | 変更内容 | このKitの該当ファイル | 修正必要性 |
|---|---|---|---|

### 非推奨化・廃止
| 機能 | 状態 | このKitの該当 | 移行先 |
|---|---|---|---|

## アップデート提案

### 即時対応
- [ ] ファイルX を変更（理由）
- [ ] ...

### 今四半期対応
- [ ] ...

### 様子見
- [ ] ...

## 自家製パックの公式移行可否

| 自家製機能 | 公式版の状態 | 移行推奨度 | 備考 |
|---|---|---|---|
| /ultrareview | ... | ... | ... |
| /ultraplan | ... | ... | ... |
| /simplify | ... | ... | ... |
| Routines | ... | ... | ... |

## 新規取り込み候補

Boris発言や新機能から、このKitに追加すべきパターン:
- ...

## 警告事項

- セキュリティ関連の変更があれば最優先
- 既存設定が動かなくなる破壊的変更があれば指摘

ルール:
- 推測で項目を増やさない。diffから確認できることのみ
- 影響度は具体的な該当ファイル名で示す
- "様子見" カテゴリも積極的に使う（焦って追従しない）
'

echo "=== Claude分析中 ===" >&2

cat "$INPUT_FILE" | claude -p "$PROMPT" --output-format text > "$OUTPUT" 2>&1

echo "" >&2
echo "✓ 提案レポート: $OUTPUT" >&2
echo "" >&2
echo "=== 先頭プレビュー ===" >&2
head -60 "$OUTPUT" >&2
