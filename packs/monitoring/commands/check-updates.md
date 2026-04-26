---
description: Boris発信・Claude Code公式docsを監視してアップデート提案を生成
argument-hint: [mode (full|recent|boris-only)]
---

$ARGUMENTS のモードでアップデート監視を実行する。引数なしならfull実行。

# 動作

`bash packs/monitoring/scripts/run-monitoring.sh` を起動して以下を順次実行:

1. **Fetch sources**:
   - GitHub releases (anthropics/claude-code, claude-code-action)
   - 公式docs (https://code.claude.com/docs/en/...)
   - Anthropic公式ニュース
   - Boris発信（複数ソース試行: rsshub / nitter / Gemini検索 / 手動投入）

2. **Diff計算**:
   - 前回snapshotとの差分抽出
   - 50字未満（typo修正等）はノイズとして除外

3. **Claude分析**:
   - 検知された変更を Kit への影響度順にランク付け
   - 即時対応 / 今四半期 / 様子見 に分類
   - 自家製パック（/ultrareview等）の公式移行可否判定
   - 新規取り込み候補のリスト化

4. **レポート出力**:
   - `packs/monitoring/snapshots/<TS>/update-proposal.md`

# 使用例

```
/check-updates
/check-updates full              # 全ソース
/check-updates boris-only        # Boris発信のみ
/check-updates recent            # 最新release のみ
```

# モード別の詳細

| モード | fetch対象 | 所要 | コスト |
|---|---|---|---|
| full | 全部（releases+docs+boris） | 5〜10分 | $0.10〜$0.30 |
| recent | releases + 主要docs のみ | 1〜3分 | $0.05〜$0.15 |
| boris-only | Borisソースのみ | 30秒〜2分 | $0.02〜$0.10 |

# 自動化との関係

この手動コマンドは GitHub Actions の `monitor-update.yml` と同じロジック。
通常は週次/月次自動実行で十分だが、緊急時（新リリース直後など）に手動trigger用。

# 出力例

```markdown
# Claude Code Kit アップデート提案

## エグゼクティブサマリー
- /loop コマンドが正式リリース（公式版）
- 自家製の routines.yml と機能重複
- 推奨: 自家製版を維持しつつ公式 /loop を併用

## 即時対応
- [ ] /loop の使い方を docs/ に追記
- [ ] schedule.md を更新

## 様子見
- [ ] /teleport は Beta のまま、本番投入待ち
```
