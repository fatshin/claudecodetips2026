#!/usr/bin/env bash
# 3つのLLM CLI（Claude/Gemini/Codex）で同じレビュータスクを並列実行
# 使い方:
#   ./packs/multi-llm/scripts/cross-review.sh diff           # git diff HEAD~1..HEAD をレビュー
#   ./packs/multi-llm/scripts/cross-review.sh pr 123         # PR #123 をレビュー
#   ./packs/multi-llm/scripts/cross-review.sh file src/foo.ts  # 単一ファイル

set -euo pipefail

MODE="${1:-diff}"
TARGET="${2:-HEAD~1..HEAD}"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR=".claude/cross-review-history/$TS"
mkdir -p "$OUT_DIR"

# === 入力データ準備 ===
INPUT_FILE="$OUT_DIR/input.txt"

case "$MODE" in
  diff)
    git diff "$TARGET" > "$INPUT_FILE"
    LABEL="git diff $TARGET"
    ;;
  pr)
    if ! command -v gh >/dev/null 2>&1; then
      echo "✗ gh コマンドが必要"; exit 1
    fi
    gh pr diff "$TARGET" > "$INPUT_FILE"
    LABEL="PR #$TARGET"
    ;;
  file)
    cat "$TARGET" > "$INPUT_FILE"
    LABEL="file $TARGET"
    ;;
  *)
    echo "使い方: $0 {diff|pr|file} <target>"
    exit 1
    ;;
esac

INPUT_SIZE=$(wc -l < "$INPUT_FILE")
echo "=== 対象: $LABEL ($INPUT_SIZE 行) ==="
echo "出力先: $OUT_DIR"

# === 共通プロンプト ===
PROMPT='以下のコード差分／コードをレビューせよ。

観点（優先順）:
1. 正しさ - 仕様一致、エッジケース、エラーパス、並行性
2. セキュリティ - 入力検証、認証認可、機密扱い、依存ライブラリ脆弱性
3. 設計 - 単一責任、結合度、抽象漏れ
4. パフォーマンス - N+1、不要I/O、アルゴリズム
5. テスト - 観点網羅、AAA、ハードコード排除
6. 可読性 - 命名、関数長

出力フォーマット（厳守）:

## 総評
LGTM / Request Changes / Block

## Critical（マージ不可、即修正必須）
- [file:line] 問題 → 修正案

## Major（修正推奨）
- [file:line] 問題 → 修正案

## Minor（後追い可）
- [file:line] 問題 → 修正案

## 良かった点
- ...

ルール:
- 推測指摘禁止。根拠にfile:lineを必ず添える
- 「動くから良い」は不可
- 修正案は擬似コードでよいので必ず添える
'

# === 並列実行 ===
PIDS=()

# Claude
if command -v claude >/dev/null 2>&1; then
  (
    cat "$INPUT_FILE" | claude -p "$PROMPT" --output-format text \
      > "$OUT_DIR/review-claude.md" 2>"$OUT_DIR/error-claude.log" \
      && echo "✓ Claude完了" || echo "✗ Claude失敗"
  ) &
  PIDS+=($!)
else
  echo "⚠ claude CLI未インストール — スキップ"
fi

# Gemini
if command -v gemini >/dev/null 2>&1; then
  (
    cat "$INPUT_FILE" | gemini -p "$PROMPT" --output-format json \
      2>"$OUT_DIR/error-gemini.log" \
      | jq -r '.response' > "$OUT_DIR/review-gemini.md" \
      && echo "✓ Gemini完了" || echo "✗ Gemini失敗"
  ) &
  PIDS+=($!)
else
  echo "⚠ gemini CLI未インストール — スキップ"
fi

# Codex
if command -v codex >/dev/null 2>&1; then
  (
    cat "$INPUT_FILE" | codex exec - \
      --sandbox read-only \
      -o "$OUT_DIR/review-codex.md" \
      "$PROMPT" 2>"$OUT_DIR/error-codex.log" \
      && echo "✓ Codex完了" || echo "✗ Codex失敗"
  ) &
  PIDS+=($!)
else
  echo "⚠ codex CLI未インストール — スキップ"
fi

# 全並列ジョブを待機
echo "=== 並列実行中（最大10分） ==="
wait "${PIDS[@]}"

# === 集約 ===
echo ""
echo "=== 集約フェーズ ==="

AGGREGATE_INPUT="$OUT_DIR/all-reviews.md"
{
  echo "# Multi-LLM Review Aggregation"
  echo ""
  echo "対象: $LABEL"
  echo ""
  for r in claude gemini codex; do
    if [ -s "$OUT_DIR/review-$r.md" ]; then
      echo "## === $r のレビュー ==="
      cat "$OUT_DIR/review-$r.md"
      echo ""
    fi
  done
} > "$AGGREGATE_INPUT"

# Claudeに集約させる（最終判断）
if command -v claude >/dev/null 2>&1; then
  cat "$AGGREGATE_INPUT" | claude -p '
上記は同一対象に対する複数LLMのレビュー。集約して以下の構造で出力:

## 🤖 Multi-LLM Synthesis

### 合意事項（複数LLMが共通指摘 ★最重要）
- [Critical] ...
- [Major] ...
- [Minor] ...

### 多数決指摘（2件以上）
- ...

### 個別意見（1件のみ、ノイズの可能性）
- claude独自: ...
- gemini独自: ...
- codex独自: ...

### 矛盾点
- 論点X:
  - claude: A
  - gemini: B
  - codex: C
  - **総合判断**: ...（理由）

### 最終判定
LGTM / Request Changes / Block
根拠: ...

ルール:
- 重複指摘は1つに統合
- 同じ問題を別表現で言及してたら合意とみなす
- 矛盾があれば両論併記、判断は保守的に（Request Changesに倒す）
' --output-format text > "$OUT_DIR/synthesis.md"

  echo ""
  echo "=== 最終結果 ==="
  cat "$OUT_DIR/synthesis.md"
else
  echo "⚠ Claude CLI不可のため集約スキップ。個別レビューは $OUT_DIR/ を参照"
fi

echo ""
echo "=== 保存先 ==="
ls -la "$OUT_DIR"
