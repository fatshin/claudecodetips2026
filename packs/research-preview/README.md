# Pack: Research Preview（自家製研究プレビュー）

## 結論

元記事のTip 25/27/28/29で紹介されている `/simplify` `/ultrareview` `/ultraplan` `/schedule` は公式の標準コマンドではない。**それらを既存のClaude Code機能（subagents、commands、CLI、GitHub Actions）の組合せで自家製実装**したパック。

## 提供物

```
research-preview/
├── commands/
│   ├── ultrareview.md       # /ultrareview: 7観点並列レビュー
│   ├── ultraplan.md         # /ultraplan: 5章詳細計画
│   ├── simplify.md          # /simplify: 3観点簡素化提案
│   └── schedule.md          # /schedule: cron + claude -p
└── workflows/
    └── routines.yml         # GitHub Actions cron実装例
```

## 各コマンドのマッピング

| 元記事Tip | 自家製実装 | 依存パック |
|---|---|---|
| #25 `/simplify` | `/simplify` | code-reviewer subagent |
| #27 `/ultrareview` | `/ultrareview` | advisors + multi-llm |
| #28 Routines | `routines.yml` + `/schedule` | GitHub Actions |
| #29 `/ultraplan` | `/ultraplan` | advisors + multi-llm |

## 設計判断

### なぜ「研究プレビュー」を自家製にするのか

元記事の研究プレビューコマンドは：
- 公式ドキュメントで存在確認できない
- 提供時期・利用条件が不明
- 有料プラン限定の可能性

→ **存在しない（または不明な）機能を待つより、標準機能の組合せで再現**したほうが確実。

### 既存パックとの依存関係

```
research-preview
   ↓ 依存
   ├─ advisors（principal/security/cost/product）
   ├─ multi-llm（gemini-advisor, codex-advisor, cross-review.sh）
   └─ 標準（code-reviewer, debugger, test-runner）
```

advisorsとmulti-llmの両方をセットアップしないと、`/ultrareview` `/ultraplan` がフル機能で動かない。

## セットアップ

```bash
# 前提: advisors + multi-llm 既にセットアップ済

# このパックを統合
cp packs/research-preview/commands/*.md   .claude/commands/
mkdir -p .github/workflows
cp packs/research-preview/workflows/*.yml .github/workflows/
```

## 使い方

### /ultrareview （最強レビュー）

```
/ultrareview pr 123
/ultrareview file src/auth/oauth.ts
/ultrareview diff main..HEAD
```

7観点並列レビュー：
- Code Reviewer（コード詳細）
- Security Advisor（OWASP・脅威）
- Principal Advisor（アーキ・長期）
- Cost Advisor（コスト試算）
- Product Advisor（ユーザー価値）
- Gemini Advisor（別視点・1M context）
- Codex Advisor（別視点・GPT-5系）

最後にClaude本体で集約。**コスト $0.50〜$2.00、所要 5〜10分**。

### /ultraplan （詳細計画）

```
/ultraplan auth serviceをsessionからJWTに移行
/ultraplan JACCS RAG basement のpgvector→S3 Vectors移行
/ultraplan SOMPO Systems AI agent本番展開
```

5章構成で計画：
1. コンテキストと目的（product-advisor）
2. アプローチ比較（principal + gemini + codex）
3. 設計詳細（principal + security）
4. 実装計画（Claude本体）
5. リスクと対策（pre-mortem）

**コスト $1〜$3、所要 40〜80分**。

### /simplify （リファクタ提案）

```
/simplify
/simplify src/billing
/simplify diff main..feature
```

3観点：重複削減 / コード品質 / 効率。即実行推奨と慎重検討に分類。

### /schedule （cron化）

```
/schedule "open PRサマリー" at "毎朝9時 平日"
/schedule "Difyのusage通知" at "0 0 * * *"
/schedule "CLAUDE.md棚卸し" at "毎週金曜17時"
```

GitHub Actions cron / ローカルcron / launchd等を自動生成。

### Routines（事前定義済cron）

`routines.yml` を `.github/workflows/` に配置するだけで以下が稼働:

| タスク | スケジュール | 内容 |
|---|---|---|
| morning-pr-summary | 平日JST 9:00 | open PR一覧Issue化 |
| weekly-claude-md-review | 金曜JST 17:00 | CLAUDE.md棚卸し |
| monthly-report | 毎月1日JST 10:00 | 前月活動レポート |

`workflow_dispatch` で手動実行も可能（テスト時）。

## アンチパターン

### ❌ /ultrareview を毎PRで使う

→ コスト爆発（毎日10PRで月 $50〜$300）。**main/protected branchへのマージ前のみ**。

### ❌ /ultraplan を小さなタスクで使う

→ プロセスのオーバーヘッドが大きすぎる。**人月単位以上の変更のみ**。

### ❌ /simplify の提案を全部採用

→ 「動くコードに手を出す」リスク。**実害のあるもの・テストで守られているもの**のみ。

### ❌ Routinesを増やしすぎ

→ GitHub Actions usage minutes 消費。**実際に読まれているレポート**のみ残す。1か月後に効果検証。

## コスト管理

```bash
# 月次のClaude API使用量確認
gh api /user/billing/usage  # GitHub Copilot系
# Anthropic コンソール
open https://console.anthropic.com/settings/usage

# Routinesの実行頻度
gh run list --workflow=routines.yml --limit 30
```

予算超過時は：
- `/ultrareview` を `/cross-review` に格下げ（advisor抜き）
- Routinesを月次のみに絞る
- /ultraplan を年に数回に限定

## 公式機能への移行

将来的にAnthropicが公式の `/ultrareview` `/ultraplan` を出した場合、自家製版を捨てて公式に移る。それまでの繋ぎとして使う。

## 関連リンク

- 元記事の30 Tips運用: ../README.md（プロジェクトルートのREADME）
- advisors: ../advisors/README.md
- multi-llm: ../multi-llm/README.md
- GitHub Actions全般: ../github-actions/README.md
