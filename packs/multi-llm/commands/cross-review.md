---
description: Claude/Gemini/Codexの3つで対象をクロスレビュー
argument-hint: [pr <番号> | diff [revision] | file <パス>]
---

3 LLMで$ARGUMENTSをレビューする。

# 手順

1. 引数を解釈:
   - `pr 123` → PR #123 の差分
   - `diff` → 最新コミットの差分（HEAD~1..HEAD）
   - `diff main..feature` → 任意リビジョンの差分
   - `file src/foo.ts` → 単一ファイル

2. `multi-llm-coordinator` subagent を起動

3. coordinator経由で `bash packs/multi-llm/scripts/cross-review.sh` を実行

4. 集約結果（synthesis.md）をユーザーに提示

5. 結果を `.claude/cross-review-history/<timestamp>/` に保存

# 出力構造

```
## Multi-LLM Review on $ARGUMENTS

### 合意事項（最重要）
- ...

### 多数決
- ...

### 矛盾点と判断
- ...

### 最終判定
LGTM / Request Changes / Block

### 詳細
個別レビュー: .claude/cross-review-history/<timestamp>/
```

# 注意

- 3 LLMの並列実行で約2〜5分かかる
- コストは1回 $0.20〜$0.80（規模次第）
- 必要なCLIが未インストールなら自動スキップ（残り2つで継続）
