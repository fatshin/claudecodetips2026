---
description: 複数のアドバイザー（principal/security/cost/product）から多角的にレビューを受ける
argument-hint: [対象。例: "PR #123" / "src/billing/refund.ts" / "新機能proposal"]
---

$ARGUMENTS について多角的レビューを実施。

# 手順

1. 対象を解釈し、Read/Grep等で内容を取得
2. 対象の性質に応じて呼ぶアドバイザーを判断:

| 対象の性質 | principal | security | cost | product |
|---|---|---|---|---|
| アーキ判断・設計proposal | ✓ | △ | ✓ | ✓ |
| 認証/認可/暗号 | △ | ✓ | - | - |
| 課金/決済 | ✓ | ✓ | △ | ✓ |
| 新規SaaS/インフラ | ✓ | △ | ✓ | △ |
| 新機能proposal | △ | △ | ✓ | ✓ |
| 大規模リファクタ | ✓ | △ | ✓ | △ |
| PoC評価 | △ | △ | ✓ | ✓ |
| セキュリティ重要なPR | △ | ✓ | - | - |

3. 該当advisorを並列起動（Taskツール経由）
4. 各advisorの結果を集約して提示

# 出力フォーマット

```markdown
# Multi-Advisor Review: $ARGUMENTS

## エグゼクティブサマリー
- 総合判定: 🟢 GO / 🟡 修正後 / 🔴 NO-GO / ⚪ 情報不足
- 主要懸念: ...
- 推奨次アクション: ...

## アドバイザー別所見

### Principal Advisor (アーキ・戦略)
（principal-advisorの結論部）

### Security Advisor (セキュリティ)
（security-advisorの結論部）

### Cost Advisor (コスト)
（cost-advisorの結論部 + 月額/年額試算）

### Product Advisor (プロダクト)
（product-advisorの結論部 + ICE）

## 合議結果

### 全員一致
- ...

### 多数派
- ...

### 矛盾と判断
- 論点X: ...
- 判断: ...

## 最終推奨
1. 即対応: ...
2. 次sprint: ...
3. 中期検討: ...
```

# 使い方の例

```
/advise PR #123
/advise src/billing/refund.ts の設計
/advise 「LLMを使った問合せ自動応答の導入」
/advise infra/terraform/bedrock-rag.tf
```

# 注意

- 複数advisorを並列起動するのでコスト数倍。重要判断のみ
- アドバイザーの意見が割れた場合、人間判断を仰ぐ
- アドバイザーは判断を**補助**するだけで、最終判断はユーザー
