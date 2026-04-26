---
description: 多重エージェントによる徹底レビュー（code-reviewer + 4 advisors + Multi-LLM）
argument-hint: [対象。例: pr 123 / file src/auth.ts / diff main..HEAD]
---

$ARGUMENTS を**最大強度**でレビュー。記事のultrareview相当を自家製で実現。

# 動作

7つの観点を並列実行：

1. **code-reviewer** subagent: コード詳細（行レベル）
2. **security-advisor** subagent: OWASP・脅威モデル
3. **principal-advisor** subagent: アーキ・長期保守性
4. **cost-advisor** subagent: コスト影響
5. **product-advisor** subagent: ユーザー価値
6. **gemini-advisor** subagent: Gemini別視点（1M context）
7. **codex-advisor** subagent: Codex別視点（GPT-5系）

すべて並列で投げて、最後にClaudeで集約。

# 手順

```bash
# 内部的に以下を実施
bash scripts/ultrareview.sh $ARGUMENTS
```

無ければ手動で：

1. 対象を読み取り（`gh pr diff` / `git diff` / `cat`）
2. 上記7 subagentを並列起動（Taskツール経由）
3. それぞれの結果を `.claude/ultrareview-history/<ts>/` に保存
4. Claudeで集約 → 最終判定

# 出力フォーマット

```markdown
# Ultrareview: $ARGUMENTS

## 🚨 最終判定
- 🟢 LGTM / 🟡 Request Changes / 🔴 Block
- 主要根拠: ...

## 観点別サマリー

| 観点 | 判定 | 主要指摘 |
|---|---|---|
| Code Quality | 🟢/🟡/🔴 | ... |
| Security | 🟢/🟡/🔴 | ... |
| Architecture | 🟢/🟡/🔴 | ... |
| Cost | 🟢/🟡/🔴 | $XX/月、... |
| Product | 🟢/🟡/🔴 | ICE=XX、... |
| Gemini View | 🟢/🟡/🔴 | ... |
| Codex View | 🟢/🟡/🔴 | ... |

## 全エージェント合意事項（★最重要）
- ...

## 多数派指摘
- ...

## 矛盾と判断
- ...

## 個別観点

### Code Reviewer
（個別の重大度別指摘）

### Security
...

### Architecture
...

### Cost
...

### Product
...

### Gemini
...

### Codex
...

## 推奨アクション順序
1. Critical: 即修正（マージ前必須）
2. Major: 修正後再レビュー
3. Minor: follow-up issueに切る
```

# 使う場面

**強く推奨**:
- main/protected branchへのマージ前
- セキュリティ系（auth/billing/payment）の変更
- アーキ判断を含むPR
- 大規模リファクタ
- リリース直前PR

**避ける場面**:
- 小さなバグ修正
- typo・フォーマット変更
- ドキュメント更新

# コスト

7観点並列実行で1回 **$0.50〜$2.00**。所要時間 5〜10分。
重要なPR・判断にのみ。
