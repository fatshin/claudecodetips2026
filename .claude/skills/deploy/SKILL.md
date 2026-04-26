---
name: deploy
description: ステージング／本番へのデプロイ手順を実行する。「デプロイ」「ship」「リリース」「stagingに上げる」と言われたら使う。コマンドは具体化する前提で雛形だけ持つ。
---

# Deploy Skill

## 前提確認（必ず先に）
1. mainブランチに出ているか（`git status` / `git rev-parse --abbrev-ref HEAD`）
2. テスト全通過か（`npm test` / `pytest`）
3. lintとtype check通過か
4. 直近のコミットがレビュー済か（`gh pr view --json mergedAt`）

ひとつでも欠けたら停止し、ユーザーに警告。

## デプロイ環境
| 環境 | コマンド | 承認 |
|---|---|---|
| staging | `npm run deploy:staging` | 不要 |
| production | `npm run deploy:prod` | 必須（ユーザー確認） |

## 実行
1. `git pull origin main`
2. `npm ci`
3. `npm run build`
4. `npm test`
5. 上記すべて通過 → デプロイコマンド実行
6. デプロイ後ヘルスチェック: `curl -f https://example.com/healthz`

## 失敗時
- ロールバック: `npm run rollback`
- Slack通知: `gh release create` などでログ残す

## カスタマイズ
このskillはプロジェクト毎に書き換える前提。コマンド・URL・ヘルスチェックエンドポイントを実環境に合わせる。
