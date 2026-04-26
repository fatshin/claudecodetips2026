# Claude Code Kit v2

Boris Cherny推奨の30 Tips + マルチLLM並走（Claude/Gemini/Codex）+ アドバイザーレビューを**コピペで動く**形にまとめたキット。

## v1からの変更点

- **packs/** ディレクトリ追加: 機能別に独立して取り込めるパック構成
- **Multi-LLM並走**: Gemini CLI / Codex CLI を並走させる仕組み
- **Advisor Reviews**: principal / security / cost / product の4視点レビュー
- **研究プレビュー**: `/ultrareview` `/ultraplan` `/simplify` `/schedule` を自家製実装
- **Issue→自動PR**: GitHub Actions経由でIssueをClaudeに実装させる
- **MCP拡充**: Dify / Bedrock / GitHub / Slack / Postgres
- **パス別CLAUDE.md**: src/billing/, src/auth/, tests/, infra/ の規約テンプレ

## ディレクトリ全体像

```
claude-code-kit/
├── CLAUDE.md                          # ルートのルールブック (Tip 4)
├── .claude/
│   ├── settings.json                  # 共有permissions+hooks+statusline
│   ├── settings.local.json.example
│   ├── hooks/
│   │   ├── protect-secrets.py         # 機密ファイル保護 (Tip 7,24)
│   │   └── auto-format.sh             # 編集後自動整形 (Tip 10)
│   ├── agents/                        # subagents (Tip 9)
│   │   ├── code-reviewer.md
│   │   ├── debugger.md
│   │   └── test-runner.md
│   ├── skills/
│   │   ├── plan-then-implement/SKILL.md  # Plan Mode (Tip 1,15)
│   │   └── deploy/SKILL.md
│   └── commands/
│       ├── kickoff.md / ship.md / review.md / learn.md
├── scripts/
│   ├── install.sh                     # ワンショット導入
│   ├── install-packs.sh               # パック選択導入 (NEW)
│   ├── worktree-spawn.sh / fanout.sh / statusline.sh
├── .github/workflows/
│   └── claude-pr.yml                  # PR自動レビュー (Tip 26)
└── packs/                              ← v2追加
    ├── mcp/                  # Dify/Bedrock/GitHub/Slack
    ├── path-claude/          # サブディレクトリ別CLAUDE.md
    ├── ts-migration/         # TypeScript移行レシピ
    ├── github-actions/       # Issue→PR自動化、multi-LLM review
    ├── multi-llm/            # Gemini/Codex並走
    ├── advisors/             # 4方向アドバイザー
    └── research-preview/     # /ultrareview, /ultraplan等
```

## クイックスタート

### 最小構成（v1相当）

```bash
cd /path/to/your/project
bash /path/to/claude-code-kit/scripts/install.sh
```

### フル構成（マルチLLM＋アドバイザー＋研究プレビュー）

```bash
cd /path/to/your/project
bash /path/to/claude-code-kit/scripts/install.sh
bash /path/to/claude-code-kit/scripts/install-packs.sh --all

# CLI追加インストール
npm install -g @anthropic-ai/claude-code @google/gemini-cli @openai/codex
brew install jq

# APIキー設定
export ANTHROPIC_API_KEY="sk-ant-xxx"
export GEMINI_API_KEY="AIzaSy-xxx"
export OPENAI_API_KEY="sk-xxx"

# .env.local編集
$EDITOR .env.local

# 動作確認
claude
> /agents              # subagent一覧
> /mcp                 # MCPサーバー接続状況
> /advise PR #123      # 多角レビュー
> /cross-review diff   # マルチLLMレビュー
> /ultrareview pr 123  # 7観点並列レビュー
```

### パック選択導入

```bash
# 個別に取り込みたい時
bash scripts/install-packs.sh --packs advisors,multi-llm
bash scripts/install-packs.sh --packs mcp
```

## 30 Tips → 実装対応表（v2版）

| # | Tip | 実装場所 | パック |
|---|---|---|---|
| 1 | Plan Mode | skills/plan-then-implement | core |
| 2 | 自己検証 | commands/ship + Stop hook | core |
| 3 | 並列worktree | scripts/worktree-spawn.sh | core |
| 4 | CLAUDE.md常時更新 | CLAUDE.md + commands/learn | core |
| 5 | skills化 | skills/ | core |
| 6 | settings.json git管理 | .claude/settings.json | core |
| 7 | permissions allow/ask/deny | settings + protect-secrets | core |
| 8 | --add-dir | filesystem MCP | mcp |
| 9 | subagents | agents + advisors/agents | core+advisors |
| 10 | PostToolUse自動整形 | hooks/auto-format.sh | core |
| 11 | PRコメント学習 | learn + GitHub Action | github-actions |
| 12 | status line | scripts/statusline.sh | core |
| 13 | Chrome拡張 | （手動） | - |
| 14 | CLI経由分析 | postgres MCP | mcp |
| 15 | Interview | skills/plan-then-implement | core |
| 16 | CLAUDE.md vs auto memory | .gitignore | core |
| 17 | パス別CLAUDE.md | path-claude/ | path-claude |
| 18 | context積極管理 | Stop hook + learn | core |
| 19 | /rewindとcheckpoints | （Claude Code標準） | - |
| 20 | MCP連携 | mcp/mcp.json | mcp |
| 21 | claude -p | fanout, ts-migration | ts-migration |
| 22 | fan-out大規模移行 | ts-migration/recipes/ | ts-migration |
| 23 | Issue連動実装 | claude-issue-implement.yml | github-actions |
| 24 | hooks強制 | protect-secrets.py | core |
| 25 | /simplify | research-preview/simplify.md | research-preview |
| 26 | GitHub Action | claude-pr.yml | github-actions |
| 27 | /ultrareview | research-preview/ultrareview.md | research-preview |
| 28 | Routines | research-preview/workflows/routines.yml | research-preview |
| 29 | /ultraplan | research-preview/ultraplan.md | research-preview |
| 30 | Remote Control | （未対応） | - |

## v2追加機能の対応表

| 機能 | コマンド | パック |
|---|---|---|
| Gemini別視点 | `/second-opinion gemini` | multi-llm |
| Codex別視点 | `/second-opinion codex` | multi-llm |
| 3 LLMクロスレビュー | `/cross-review` | multi-llm |
| 4方向アドバイザー | `/advise` | advisors |
| アーキ判断（ADR形式） | `/arch-review` | advisors |
| 事前死亡診断 | `/pre-mortem` | advisors |
| Issue→自動PR | `@claude implement` ラベル | github-actions |
| Issue自動triage | （Issue起票で自動） | github-actions |
| マルチLLM PR review | （5+ファイルPRで自動） | github-actions |
| 朝のPRサマリー | routines.yml | research-preview |
| 週次CLAUDE.md棚卸し | routines.yml | research-preview |

## コマンド早見表

| コマンド | 用途 | コスト | 所要時間 |
|---|---|---|---|
| `/kickoff <task>` | 新規タスク開始 | $0.01 | 数秒 |
| `/ship` | 検証→PR作成 | $0.05 | 1〜3分 |
| `/review` | 直近差分レビュー | $0.05 | 1分 |
| `/learn` | CLAUDE.md追記 | $0.01 | 数秒 |
| `/second-opinion gemini` | Gemini別視点 | $0.02 | 30秒 |
| `/second-opinion codex` | Codex別視点 | $0.05 | 1分 |
| `/cross-review <target>` | 3 LLM並列 | $0.20 | 3〜5分 |
| `/advise <target>` | 4方向アドバイザー | $0.10 | 2〜4分 |
| `/arch-review <target>` | ADR形式アーキ | $0.20 | 3〜5分 |
| `/pre-mortem <target>` | 事前死亡診断 | $0.30 | 4〜6分 |
| `/simplify [target]` | 簡素化提案 | $0.10 | 1〜2分 |
| `/ultrareview <target>` | 7観点並列 | $1.00 | 5〜10分 |
| `/ultraplan <task>` | 5章詳細計画 | $2.00 | 40〜80分 |

## 推奨運用パターン

### パターン1: 日常開発

```
/kickoff <task>          # Plan Mode
（実装）
/ship                    # 検証→PR
```

### パターン2: 重要PR

```
/kickoff <task>
（実装）
/ship
/cross-review pr <num>   # 3 LLMレビュー
（合意事項を即修正）
/advise pr <num>         # 4方向アドバイザー（必要なら）
```

### パターン3: 最大強度レビュー

```
/ultrareview pr <num>    # 7観点並列
（高コストだが最重要PRはこれ）
```

### パターン4: アーキ判断

```
/ultraplan <task>        # 詳細計画
（人間レビュー）
/arch-review proposal.md # ADR化
/pre-mortem <task>       # 失敗逆算
（最終判断）
```

### パターン5: モジュール特化

```
（auth実装後）
/advise src/auth/oauth.ts          # security-advisor自動起動
/cross-review file src/auth/oauth.ts  # Gemini/Codex別視点
```

## トラブルシューティング

各パックのREADME参照。問題切り分けは:

1. `claude --version` でCLI正常か
2. `/agents` でsubagent全部読まれているか
3. `/mcp` でMCPサーバー接続できているか
4. `cat .claude/settings.json | jq` で構文OKか
5. `bash -n .claude/hooks/*.sh` でhook構文OKか
6. APIキーが設定されているか（Anthropic/Gemini/OpenAI）

## 公式リファレンス

- Claude Code: https://code.claude.com/docs/en/overview
- Gemini CLI: https://google-gemini.github.io/gemini-cli/
- Codex CLI: https://developers.openai.com/codex/cli
- claude-code-action: https://github.com/anthropics/claude-code-action

## ライセンス

MIT
