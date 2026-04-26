# Pack: Advisor Reviews（多角的レビュー）

## 結論

`code-reviewer` がコード詳細を見るのに対し、こちらは **戦略・セキュリティ・コスト・プロダクト** の視点で多角的にレビューする。重要判断の前に**4方向から殺意高く詰める**ためのパック。

## 提供物

```
advisors/
├── agents/
│   ├── principal-advisor.md       # アーキ・戦略・長期保守性
│   ├── security-advisor.md        # OWASP・脅威モデル
│   ├── cost-advisor.md            # 月額/年額試算・FinOps
│   └── product-advisor.md         # JTBD・指標・ICE
└── commands/
    ├── advise.md                  # /advise <対象>: 4方向レビュー
    ├── arch-review.md             # /arch-review: ADR形式集約
    └── pre-mortem.md              # /pre-mortem: 失敗逆算
```

## セットアップ

```bash
cp packs/advisors/agents/*.md     .claude/agents/
cp packs/advisors/commands/*.md   .claude/commands/
```

## 使い方

### 1. 多角的レビュー（標準）

```
/advise PR #123
/advise src/billing/refund.ts の設計
/advise 「LLMによる問合せ自動応答システムの導入」
```

→ 対象の性質に応じて該当advisorを並列起動 → 集約

### 2. アーキテクチャ判断

```
/arch-review JACCS RAG の OpenSearch vs pgvector 比較
/arch-review Bedrock Agents vs Dify Workflow 選定
```

→ ADR形式で出力。意思決定ドキュメント化に直接使える。

### 3. Pre-mortem（事前死亡診断）

```
/pre-mortem JACCS WebEntry paperless 計画
/pre-mortem SOMPO Systems AI agent 導入
```

→ 失敗シナリオTop5＋事前対策＋撤退基準

## advisor選択マトリクス

| 状況 | 主担当 | 副担当 | 必要度 |
|---|---|---|---|
| 認証/認可 PR | security | principal | 🔴 必須 |
| 課金/決済 PR | security + product | principal | 🔴 必須 |
| 新規SaaS/インフラ | cost | principal | 🔴 必須 |
| LLM API本番組込 | cost + security | principal | 🔴 必須 |
| 新機能proposal | product | principal | 🟡 推奨 |
| 大規模リファクタ | principal | cost | 🟡 推奨 |
| アーキ判断 | principal | 全員 | 🔴 必須 |
| マイクロサービス分割 | principal | cost | 🟡 推奨 |
| PoC評価 | product | cost | 🔴 必須 |

## advisor間の役割分担

```
        ┌─────────────────────────────────┐
        │       Principal Advisor         │
        │   （戦略・アーキ・長期保守性）   │
        └──────┬──────────────────────────┘
               │
       ┌───────┴───────┬──────────────┐
       │               │              │
┌──────▼─────┐ ┌──────▼─────┐ ┌──────▼─────┐
│  Security  │ │    Cost    │ │  Product   │
│   OWASP    │ │   FinOps   │ │    JTBD    │
│  脅威モデル │ │   月額試算  │ │   ICE指標  │
└────────────┘ └────────────┘ └────────────┘
```

## 既存subagentとの関係

```
コード詳細レビュー（行レベル） ← code-reviewer
   ↓
モジュール設計レビュー        ← principal-advisor
   ↓
セキュリティ監査              ← security-advisor
   ↓
コスト評価                    ← cost-advisor
   ↓
プロダクト価値評価             ← product-advisor

合議による最終判定 ← /advise コマンド
```

## マルチLLMパックとの併用

最強の組合せ:

```bash
# 1. アーキproposalを書く
/kickoff Bedrock RAG vs Dify hybrid 構成

# 2. Claudeで4 advisor合議
/advise 「新proposal」

# 3. さらにGemini/Codexの観点も入れる
/cross-review file proposal.md

# 4. 集約結果を見て人間判断
```

→ Claude×4 advisor + Gemini + Codex = **6視点の合議**

## コスト

| コマンド | 平均コスト | 所要時間 |
|---|---|---|
| `/advise` (2 advisor) | $0.05〜$0.15 | 1〜2分 |
| `/advise` (4 advisor) | $0.10〜$0.30 | 2〜4分 |
| `/arch-review` | $0.15〜$0.40 | 3〜5分 |
| `/pre-mortem` | $0.20〜$0.50 | 4〜6分 |

組み合わせて使うと累積するので注意。重要判断のみ。

## アンチパターン

### ❌ 全PRで /advise を使う
→ コスト爆発・レビュー疲れ。重要なPRのみ。

### ❌ advisorの結論を鵜呑み
→ あくまで**判断補助**。最終判断は人間。advisor同士が矛盾したら自分で考える。

### ❌ advisorに質問せず一方通行
→ Pre-mortemや/adviseの結果に対して反論・質問を続けて磨く。1ターンで終わらせない。

### ❌ コスト見積を「だいたい」で済ます
→ cost-advisorの試算は必ず**前提値を明示**して数字で出させる。
