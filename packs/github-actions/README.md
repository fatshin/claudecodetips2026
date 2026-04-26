# Pack: GitHub Actions（Issue→PR + Multi-LLM Review）

## 結論

GitHub IssueとPRをClaude/Gemini/Codexで自動駆動する3つのworkflow。

| ワークフロー | トリガー | 効果 |
|---|---|---|
| `claude-issue-implement.yml` | Issueに `@claude implement` コメント or `claude:implement` ラベル | Issueを読んで実装→PR作成 |
| `claude-issue-triage.yml` | Issue作成・再オープン | 自動分類・優先度・ラベル付与 |
| `multi-llm-review.yml` | PR作成・更新（5ファイル以上 or `multi-review` ラベル） | Claude/Gemini/Codexで並列レビュー→集約 |

## セットアップ

```bash
# 1. ファイル配置
mkdir -p .github/workflows
cp packs/github-actions/*.yml .github/workflows/

# 2. GitHub Secretsに必要なキーを登録
gh secret set ANTHROPIC_API_KEY --body "sk-ant-xxx"
gh secret set GEMINI_API_KEY    --body "AIzaSy-xxx"
gh secret set OPENAI_API_KEY    --body "sk-xxx"

# 3. ラベル作成（triage用）
gh label create "claude:implement" --color "0E8A16" --description "Auto-implement by Claude"
gh label create "multi-review"     --color "1D76DB" --description "Trigger multi-LLM review"
gh label create "priority:p0"      --color "B60205"
gh label create "priority:p1"      --color "D93F0B"
gh label create "priority:p2"      --color "FBCA04"
gh label create "priority:p3"      --color "C2E0C6"
gh label create "size:xs" "size:s" "size:m" "size:l" "size:xl" --color "BFD4F2"
gh label create "area:auth" "area:billing" "area:api" "area:ui" "area:infra" --color "5319E7"

# 4. PR作成して動作確認
gh issue create --title "test: triage動作確認" --body "適当なfeature request"
# → triage workflowが走ってラベルが付くはず
```

## ワークフロー詳細

### Issue → 自動実装

**起動方法（2通り）:**

```bash
# 方法1: コメントで起動
gh issue comment 123 --body "@claude implement"

# 方法2: ラベル付与で起動
gh issue edit 123 --add-label "claude:implement"
```

**動作:**
1. Issueに「実装着手」コメント
2. ブランチ作成（`feat/issue-123`）
3. 実装 → テスト → lint → typecheck
4. すべて通過したらPR作成（`Closes #123`）
5. 失敗時はIssueに状況返信

**安全装置:**
- 失敗時は人間に通知してマージしない
- `allowed_tools` で実行可能コマンドを制限
- PRは別ブランチに作るので main直接変更しない

### Issue Triage

**動作:**
- 種別・影響範囲・優先度・工数のラベル自動付与
- 不足情報があれば質問コメント
- p0/p1かつxs/sなら自動実装ラベルも付与
- 重複Issueの検知

### Multi-LLM Review

**並列実行のフロー:**
```
PR作成
  ├─ claude review  ─┐
  ├─ gemini review  ─┼→ aggregate (Claudeで集約)
  └─ codex  review  ─┘     ↓
                         PR本文にコメント投稿
```

**特徴:**
- 3 LLMの**合意事項**を最重要扱い（精度高い）
- **多数決**指摘も注目
- **個別指摘**はノイズの可能性ありとして表示
- 矛盾する指摘は両論併記

**起動条件:**
- `multi-review` ラベル付与、または
- 変更ファイル5件以上のPR

**コスト目安（1PR約500行diff）:**
- Claude: $0.05〜0.15
- Gemini: $0.02〜0.08（Flash使用時）/ $0.10〜0.30（Pro）
- Codex: $0.10〜0.40
- 合計: 1PR約 **$0.20〜0.80**

## トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| `@claude implement` 反応無し | Secrets未設定 | `gh secret list` で確認 |
| 実装が中途半端でPR | テスト未通過 | `allowed_tools` のテストコマンド確認 |
| Multi-LLM review が3つ全部失敗 | API key期限切れ | 各サービスで再発行 |
| Codexがsandbox違反 | `--sandbox read-only` 指定漏れ | workflow yamlを確認 |

## 高度なカスタマイズ

### 特定ブランチだけ自動実装

```yaml
on:
  issue_comment:
    types: [created]
jobs:
  implement:
    if: |
      contains(github.event.comment.body, '@claude implement') &&
      github.event.issue.milestone.title == 'sprint-current'
```

### 自動実装の対象ファイル制限

`direct_prompt` に追記:

```
重要: 以下のファイルは触らないこと（人間レビュー必須）
- src/auth/**
- src/billing/**
- infra/**
```

### 段階承認

p0/p1のIssueはCODEOWNERS経由で2人承認後にマージ:

```yaml
# .github/CODEOWNERS
src/auth/    @security-team
src/billing/ @platform-team @security-team
infra/       @sre-team
```
