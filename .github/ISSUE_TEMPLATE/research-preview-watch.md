---
name: 研究プレビュー機能ウォッチ
about: Claude Code の研究プレビュー機能（Remote Control / Routines / /loop / /teleport / /branch等）の最新動向をウォッチ
title: '[Watch] 研究プレビュー機能調査 YYYY-MM-DD'
labels: ['research-preview', 'watch']
assignees: ''
---

## ウォッチ対象機能

定期的に以下の機能の公式リリース状況・仕様変更を確認する。

- [ ] **Remote Control**: ローカルからクラウド上Claude Codeセッション操作
- [ ] **/teleport**: クラウド↔ローカル間のセッション継続
- [ ] **/loop**: 定期実行（`/loop 5m /babysit` 等）
- [ ] **/branch / /fork-session**: セッション分岐
- [ ] **/batch**: 大規模並列実行のintegrated UI
- [ ] **/simplify**: refactor提案（公式版）
- [ ] **/ultrareview / /ultraplan**: 深層レビュー・計画
- [ ] **Routines**: スケジュール実行管理
- [ ] **WorktreeCreate hook**: 非git VCS用
- [ ] **Dispatch**: secure remote control for desktop
- [ ] **Channels**: MCPサーバーからのpush message
- [ ] **iOS/Android Code tab**: モバイルからのClaude Code

## 確認方法

```bash
# Claude Codeバージョン確認
claude --version

# CHANGELOGチェック
gh release list --repo anthropics/claude-code --limit 10

# 最新リリースのCHANGELOG
gh release view --repo anthropics/claude-code --json body | jq -r .body | head -80

# 利用可能なslash commandの確認
claude
> /help                # 全コマンド一覧
> /<予想コマンド名>     # 存在確認

# 公式ドキュメント map
open https://code.claude.com/docs/en/overview
open https://docs.claude.com/en/docs/claude-code/claude_code_docs_map.md

# Boris Cherny の発信
open https://threads.com/@boris_cherny
open https://x.com/bcherny
```

## 確認手順

### 1. 標準コマンド確認

`/help` で表示される標準コマンド一覧を取得:

```bash
echo "/help" | claude --output-format text > /tmp/claude-commands.txt
diff <(cat /tmp/claude-commands-prev.txt) /tmp/claude-commands.txt
```

新規コマンドが増えていれば本Issueに記録。

### 2. 公式ドキュメント変更確認

```bash
# 公式docsをmirror (初回)
git clone https://github.com/anthropics/claude-code-docs /tmp/cc-docs

# 差分確認 (定期)
cd /tmp/cc-docs && git pull
git log --since="last month" --pretty=format:"%h %s"
```

### 3. 機能別判定

各機能について以下を判定:

| 状態 | 説明 | アクション |
|---|---|---|
| 🟢 GA | 安定版でリリース済 | 自家製版を捨てて公式版へ移行 |
| 🟡 Beta | ベータ提供中 | 試験運用、問題なければ移行 |
| 🟠 Preview | 研究プレビュー、限定提供 | 仕様確認、自家製版を維持 |
| 🔴 未公開 | 未確認・噂のみ | ウォッチ継続 |

## 結果記録

各機能について以下フォーマットで記入。

### Remote Control

- 状態: 🟠 Preview / 🟡 Beta / 🟢 GA / 🔴 未公開
- 確認日: YYYY-MM-DD
- 公式URL: <URL>
- 必要バージョン: claude-code vX.Y.Z
- 必要プラン: Pro / Max / Team / Enterprise
- 仕様変更点（前回比）: ...
- 自家製版との比較: ...
- アクション: 移行 / 並走 / 様子見

### /teleport

（同様）

### /loop

（同様）

### /branch

- 状態: 🟢 GA（Boris発言で確認済、`claude --resume <id> --fork-session`）
- ...

### /batch & /simplify

（同様）

### /ultraplan & /ultrareview

（同様）

### Routines

（同様）

## 結論・次回ウォッチ予定

- 次回ウォッチ: YYYY-MM-DD（1か月後）
- 緊急で確認すべき変化: ...
- 自家製パックへの影響: ...
