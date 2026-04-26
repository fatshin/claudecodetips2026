---
description: アーキテクチャ・設計判断のレビュー（principal-advisor + 関連advisor）
argument-hint: [対象。例: "RAGアーキ proposal" / "新マイクロサービス設計"]
---

$ARGUMENTS のアーキテクチャレビューを実施。

# 手順

1. 対象を読み取り（proposalドキュメント、ADR、設計図、コード）
2. **principal-advisor** を起動（必須）
3. 対象の性質に応じて以下も起動:
   - インフラ含む → cost-advisor
   - データ・認証含む → security-advisor
   - ユーザー価値含む → product-advisor

4. 各advisor並列実行 → 集約

# 重点観点

## 技術選定の妥当性
- なぜこの言語／FW／DB／クラウド／LLMか
- 代替案の比較表（最低3案）
- 5年後の運用コストとリスク

## 境界の引き方
- マイクロサービスならその境界が妥当か
- データ所有権の明確さ
- API契約の安定性

## 拡張性・撤退性
- スケール時のボトルネック
- 機能追加時の影響範囲
- 撤退・移行のコスト

## 組織能力
- このアーキを運用できる人材確保
- 既存技術スタックとの整合
- 学習コスト

# 出力

```markdown
# Architecture Review: $ARGUMENTS

## 総合判定
- 🟢 採用推奨 / 🟡 条件付き採用 / 🔴 別案推奨 / ⚪ 情報不足

## ADR形式の要約
- **Context**: なぜこの判断が必要か
- **Decision**: 何を採用するか
- **Consequences**:
  - Positive: ...
  - Negative: ...
  - Neutral: ...
- **Alternatives Considered**: A案 / B案 / C案

## アドバイザー別所見
（各advisorの結論部）

## 残課題
- 解決すべき問い: ...
- 必要な追加調査: ...

## 次アクション
- PoC / プロトタイプ範囲: ...
- 意思決定の期限: ...
```

# 使い方の例

```
/arch-review JACCS RAG basement の OpenSearch vs pgvector vs S3 Vectors 比較
/arch-review SOMPO Systems AI agent のDify vs Bedrock Agents 選定
/arch-review Mirumiru Project のモバイル実装方式（Native vs RN vs Flutter）
```
