# Project Memory (CLAUDE.md)

このファイルは Claude Code がセッション開始時に自動読込するルールブック。
**容赦なく編集する。同じミスが2回目に出たら追記。不要になったら削除。**

## 役割と進め方

- 大きい変更は **Plan Mode** から（`/kickoff` で起動可）
- 完了前に必ず **自己検証**（lint/test/型チェック/動作確認）
- レビューは **code-reviewer subagent** へ委譲
- テスト全量出力は **test-runner subagent** に消化させる（contextを汚さない）

## Conventions

### 言語別
- TypeScript: strict mode必須。any禁止（unknown→narrowingで）
- Python: type hints必須。`from __future__ import annotations` を冒頭に。
- 命名: 関数=動詞句、boolean=`is_/has_/should_`、定数=UPPER_SNAKE_CASE

### コミット
- Conventional Commits（`feat:` `fix:` `chore:` `refactor:` `test:` `docs:`）
- 1コミット1関心事。混ぜない。
- メッセージ本文に「Why」を書く（What はdiffを見れば分かる）

### テスト
- 新規機能は単体テストとセット
- バグ修正は再発防止テストを必ず追加
- AAA構造（Arrange / Act / Assert）

## Build & Test

```bash
# セットアップ
npm ci         # or: pnpm install --frozen-lockfile / uv sync

# 開発
npm run dev    # or: uv run python -m project

# 検証（PR前にすべて通す）
npm run lint
npm run typecheck
npm test
```

## Pitfalls（過去のミスから学習）

- `.env` 系ファイルは Read/Write しない（hookでブロック済）
- `git push --force` は禁止（保護ブランチで弾く設定だが念のため）
- マイグレーションは up/down 両方書く
- 外部API呼出はリトライ＋タイムアウト必須

## Architecture（このプロジェクト固有）

- src/foo: ...
- src/bar: ...

> **編集ガイド**: 局所的なルールは `src/<area>/CLAUDE.md` に降ろす。ここはプロジェクト全体の規約のみ。

## Out of Scope

- 個人の好み（snake_case vs camelCaseの趣味判断など）→ 議論はせずプロジェクト標準に従う
- パフォーマンス最適化の早すぎる実施 → 計測してから

---
最終更新: YYYY-MM-DD（追記時に書き換え）
