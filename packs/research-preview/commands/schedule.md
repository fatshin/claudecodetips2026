---
description: 反復タスクをcron + claude -pで自動化する設定を生成
argument-hint: [タスク内容] at [cron式 または 自然言語スケジュール]
---

$ARGUMENTS を反復実行するスケジュール設定を作成。

# 動作

1. ユーザー入力をパース:
   - タスク内容（何をやるか）
   - スケジュール（いつ実行するか）

2. 適切な実装方式を選択:
   - **GitHub Actions cron**: リポジトリに紐づくタスク（PR review、issue triage、ドキュメント更新）
   - **ローカルcron**: 個人マシンで動かすタスク（朝の状況確認、定期サマリー）
   - **launchd (macOS)** / **systemd timer (Linux)**: 同上、より堅牢

3. 設定ファイル＋実行スクリプトを生成

# 出力例

## 例1: 「毎朝9時にopen PRをサマリー」

→ GitHub Actions推奨

```yaml
# .github/workflows/morning-pr-summary.yml
name: Morning PR Summary
on:
  schedule:
    - cron: '0 0 * * 1-5'  # JST 9:00 平日（UTC 0:00）
  workflow_dispatch:

jobs:
  summary:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          direct_prompt: |
            open状態のPRを取得し、以下のサマリーを生成:
            - レビュー待ちPR一覧（assignee別）
            - マージ可能だが未マージのPR
            - CI失敗中のPR
            - 1週間以上動きのないPR

            結果を docs/daily-pr-summary.md に書き出し、
            git commit & push して main を更新。
          allowed_tools: |
            Bash(gh pr list*),Bash(gh pr view*),Bash(git*),
            Read,Edit,Write
```

## 例2: 「毎週金曜にCLAUDE.md棚卸し」

→ GitHub Actions推奨

```yaml
# .github/workflows/weekly-claude-md-review.yml
name: Weekly CLAUDE.md Review
on:
  schedule:
    - cron: '0 8 * * 5'  # JST 17:00 金曜
  workflow_dispatch:

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          direct_prompt: |
            CLAUDE.md（プロジェクトルート + サブディレクトリ全部）を読み:
            1. 過去1か月で参照されてなさそうなルールを抽出
            2. コードと矛盾するルールを検出
            3. 削除候補リストを Issue として起票

            Issue title: "CLAUDE.md weekly review YYYY-MM-DD"
            Issue body: 削除候補リスト + 理由 + 確認すべき箇所
          allowed_tools: |
            Bash(gh issue create*),Read,Grep,Glob
```

## 例3: 「毎日朝9時にDify使用量を確認してSlack通知」

→ ローカルcron推奨

```bash
# crontab -e に追加
0 9 * * 1-5 /usr/local/bin/claude-daily-dify-check.sh
```

```bash
#!/usr/bin/env bash
# /usr/local/bin/claude-daily-dify-check.sh
set -euo pipefail
cd /Users/me/projects/myproj

claude -p '
DifyのAPI管理画面（https://api.dify.ai）からusage取得して、
昨日の使用量サマリーをSlack #ai-ops チャンネルに投稿:
- workflow実行回数
- LLMトークン消費
- エラー率
- 異常があれば赤マーク

dify MCPで取得 → slack MCPで投稿。
' --output-format text > /tmp/dify-check.log

# エラー時はpushover等で通知
[ $? -ne 0 ] && curl -s -F "user=$PUSHOVER_USER" -F "token=$PUSHOVER_TOKEN" \
  -F "message=Dify check failed: $(tail -3 /tmp/dify-check.log)" \
  https://api.pushover.net/1/messages.json
```

# cron式チートシート

```
分 時 日 月 曜
*  *  *  *  *

# 例
0 9 * * 1-5     平日9:00 (UTC)
0 0 * * 1-5     JST 9:00 平日（UTCに対して -9）
0 0 1 * *       毎月1日 0:00 UTC
0 8 * * 5       毎週金曜 8:00 UTC = JST 17:00
*/15 * * * *    15分おき
```

# JST↔UTC変換

GitHub Actionsはcron式がUTC基準。日本時間で考えるなら -9時間：

| JST | UTC | cron |
|---|---|---|
| 9:00 | 0:00 | `0 0 * * *` |
| 12:00 | 3:00 | `0 3 * * *` |
| 17:00 | 8:00 | `0 8 * * *` |
| 0:00 | 15:00 | `0 15 * * *` |

# 注意

- GitHub Actions cron は遅延あり（5〜15分のずれ）。シビアな時刻が必要ならローカルcron
- private repoは cron 60日間アクティビティ無いと停止される（適宜commitすること）
- ローカルcron はマシン起動時のみ動作。定常稼働マシンが必要
- API key を Secrets/環境変数経由で注入すること

# 使い方

```
/schedule "open PRを朝9時にサマリー" at "毎朝9時 平日"
/schedule "Difyのusageを確認してSlack通知" at "0 0 * * *"
/schedule "CLAUDE.md棚卸し" at "毎週金曜17時"
```
