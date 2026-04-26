---
description: 検証→コミット→PR作成までを一気通貫で実行
argument-hint: [PRタイトル（任意）]
---

タスク完了からPR作成まで実行する。

# 手順
1. **自己検証**
   - lint: `npm run lint` or `ruff check`
   - format確認: `npm run format:check` or `ruff format --check`
   - テスト: `npm test` or `pytest`
   - すべて通過したら次へ。1つでも落ちたら修正してから戻る。

2. **差分確認**
   - `git status` と `git diff` で意図しない変更がないか確認
   - 不要ファイル（デバッグprint、コメントアウト残骸）を除去

3. **コミット**
   - Conventional Commits形式で1〜複数コミットに整理
   - 例: `feat(auth): add OAuth2 google provider`
   - 例: `fix(api): handle null user in middleware`

4. **PR作成**
   - `git push -u origin HEAD`
   - `gh pr create --fill` または `gh pr create --title "$ARGUMENTS"`
   - PR本文には以下を含める:
     - 何を変えたか（What）
     - なぜ変えたか（Why）
     - 動作確認手順（How verified）
     - スクリーンショット（UI変更時）

5. **code-reviewer subagentを呼ぶ**
   - 自分のPRを@code-reviewerでセルフレビュー
   - 指摘事項があれば直してforce push（許可される場合のみ）

# 失敗時
- テスト落ちる → debugger subagent起動
- 想定外の差分 → /rewindで戻すか、git stashで退避
