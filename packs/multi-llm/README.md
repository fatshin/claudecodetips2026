# Pack: マルチLLM並走（Claude + Gemini + Codex）

## 結論

3つのコーディングLLM CLIを並走させて、**合意・多数決・矛盾**を可視化する。重要な判断やレビューでの精度を上げるためのパック。

## 提供物

```
multi-llm/
├── agents/
│   ├── gemini-advisor.md          # Gemini CLI呼び出し
│   ├── codex-advisor.md           # Codex CLI呼び出し
│   └── multi-llm-coordinator.md   # 3者集約司令塔
├── commands/
│   ├── cross-review.md            # /cross-review
│   └── second-opinion.md          # /second-opinion
└── scripts/
    └── cross-review.sh            # 並列実行＋集約
```

## 前提インストール

```bash
# Claude Code（メイン）
npm install -g @anthropic-ai/claude-code

# Gemini CLI
npm install -g @google/gemini-cli

# Codex CLI
npm install -g @openai/codex

# 認証確認
claude  --version
gemini  --version
codex   --version

# 環境変数
export ANTHROPIC_API_KEY="sk-ant-xxx"
export GEMINI_API_KEY="AIzaSy-xxx"
export OPENAI_API_KEY="sk-xxx"

# jq（集約に使用）
brew install jq      # macOS
apt-get install jq   # Linux
```

## セットアップ

```bash
# プロジェクトの.claude/に統合
cp packs/multi-llm/agents/*.md      .claude/agents/
cp packs/multi-llm/commands/*.md    .claude/commands/
mkdir -p scripts
cp packs/multi-llm/scripts/*.sh     scripts/
chmod +x scripts/cross-review.sh
```

## 使い方

### 1. 軽量セカンドオピニオン

```
/second-opinion gemini このSQLの実行計画を分析して
/second-opinion codex このソートアルゴリズムを最適化
```

→ `gemini-advisor` または `codex-advisor` subagentが該当CLIを呼んで結果を返す。

### 2. クロスレビュー（重め・正確）

```
/cross-review pr 123          # PR #123 を3 LLMでレビュー
/cross-review diff            # 最新コミット差分
/cross-review diff main..HEAD # 任意レンジ
/cross-review file src/auth.ts
```

→ `cross-review.sh` が3つを並列実行し、Claudeで集約 → synthesis.md出力。

### 3. 直接スクリプト

```bash
bash scripts/cross-review.sh diff
bash scripts/cross-review.sh pr 456
bash scripts/cross-review.sh file src/billing/calculator.ts
```

## 役割分担の戦略

| タスク | 主担当 | 副担当 | 監査 |
|---|---|---|---|
| 通常実装 | Claude Code | - | - |
| アーキ判断 | Claude（Plan Mode） | Gemini（広視野）・Codex（別解） | 全員合議 |
| セキュリティ重要なPR | Claude | - | Codex（独立検証） |
| 大規模コード把握 | Gemini（1M context） | Claude（要約） | - |
| アルゴリズム最適化 | Codex（GPT-5系強み） | Claude（実装） | Gemini（性能影響） |
| 多言語混在リポジトリ | Gemini | Claude | - |

## コスト管理

3 LLM並列はコスト3〜5倍。**毎回使うものではない**。

| ケース | 推奨 |
|---|---|
| 通常のPR（< 100行） | 単独レビュー（Claudeのみ） |
| 中規模PR（100〜500行） | `/second-opinion` で1つ追加 |
| 重要PR（mainマージ、認証/課金） | `/cross-review` フル合議 |
| アーキ判断 | フル合議＋人間判断 |

## サンプル: 認証実装の合議フロー

```bash
# 1. Plan Modeで計画（Claude）
/kickoff OAuth2 Google providerを認証フローに追加

# 2. 実装（Claude）
（通常通り進める）

# 3. レビュー（フル合議）
/cross-review diff main..HEAD

# 4. 結果確認
# → 合意事項 = 即修正
# → 矛盾点 = 人間判断
# → 個別意見 = 任意

# 5. 修正反映後にPR作成
/ship "feat(auth): add OAuth2 Google provider"
```

## トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| `gemini` が認証エラー | GEMINI_API_KEY未設定 | `gemini` で対話起動して `/auth` |
| `codex` が認証エラー | OPENAI_API_KEY未設定 | `codex login` でOAuth |
| 並列実行で1つだけ完了 | API rate limit | 順次実行に切替（cross-review.shを修正） |
| jq not found | jq未インストール | `brew install jq` |
| 集約結果が空 | 個別レビュー全失敗 | `error-*.log` を確認 |

## 公式リファレンス

- **Gemini CLI**: https://google-gemini.github.io/gemini-cli/
- **Codex CLI**: https://developers.openai.com/codex/cli
- **Codex Non-interactive**: https://developers.openai.com/codex/noninteractive

## 設計上の判断

**なぜCodexで実装させずレビュー中心？**
- Codexの`workspace-write`は強力だがClaude Codeのhook/permissions/CLAUDE.md統合外
- レビュー（read-only）なら副作用無しで使い捨てに最適
- 実装はClaude一本化、レビューでアンサンブル、というのが現状の最適解

**なぜGemini Pro 2.5を使うのか？**
- 1M contextが他にない（Claudeでも今のところ200k）
- 大規模リポジトリ把握・大量ログ解析で圧倒的有利
- 無料枠あり（個人開発者）
