# Pack: TypeScript fan-out 移行レシピ

## 結論

`fanout.sh` を土台に、典型的なTS移行を**安全装置付きスクリプト**化したもの。  
**いきなり全量実行しない**設計。デフォルトdry-runで5件試行、`--all` 明示で全量。

## レシピ一覧

| スクリプト | 用途 | 想定所要時間 |
|---|---|---|
| `class-to-functional.sh` | React Class→Functional + Hooks | 50ファイルで30〜60分 |
| `cjs-to-esm.sh` | CommonJS require → ES Modules import | 100ファイルで20〜40分 |
| `proptypes-to-ts.sh` | PropTypes → TypeScript型注釈 | 50ファイルで20〜40分 |
| `strict-mode.sh` | tsconfig strictフラグ段階有効化 | フラグ1個ごと10〜30分 |

## 実行手順（共通）

```bash
# 1. クリーンな状態にする（必須）
git status        # cleanであること
git checkout -b migrate/<recipe-name>

# 2. dry-run（先頭5件のみ）
./packs/ts-migration/recipes/class-to-functional.sh

# 3. 結果をレビュー
git diff
npm test          # テスト通過確認

# 4. 問題なければ全量実行
./packs/ts-migration/recipes/class-to-functional.sh --all

# 5. 全量結果を再度レビュー、テスト
git diff --stat
npm test
npm run typecheck

# 6. コミット（細かく分ける）
git add -p
git commit -m "refactor: migrate <component-group> to functional components"
```

## strict-mode.sh の特殊運用

strict mode は1フラグずつ有効化するのが鉄則。**一気に `strict: true` にすると修正不能なエラー数になる**。

```bash
# 推奨: --next で順次処理
./packs/ts-migration/recipes/strict-mode.sh --next

# 個別フラグ指定
./packs/ts-migration/recipes/strict-mode.sh strictNullChecks
```

順序（影響度の小さい順）:
1. `noImplicitThis`
2. `alwaysStrict`
3. `strictBindCallApply`
4. `noImplicitAny`           ← ここから影響大
5. `strictNullChecks`        ← 一番工数かかる
6. `strictFunctionTypes`
7. `strictPropertyInitialization`

各フラグ完了ごとにPRを分けてマージ。1PRに2つ以上のフラグを混ぜない。

## 実行前チェックリスト

- [ ] `git status` がclean
- [ ] テストが全通過している（移行前のbaseline）
- [ ] CIが通っている
- [ ] 別worktreeで実行（`scripts/worktree-spawn.sh` 併用推奨）
- [ ] 5件dry-runで動作確認済

## fan-out失敗時のリカバリ

```bash
# ログ確認
ls -la .claude/fanout-logs/

# 失敗ファイルだけ抽出
grep -l FAIL .claude/fanout-logs/<timestamp>/*.log | \
  sed 's|.*/||;s/_/\//g;s/\.log$//' > retry-files.txt

# 再実行
bash scripts/fanout.sh retry-files.txt "<元のプロンプト>" -a
```

## カスタムレシピの作り方

1. `recipes/your-migration.sh` を作る
2. `class-to-functional.sh` をテンプレに以下を埋める:
   - 対象ファイルの抽出パターン（rg）
   - 変換プロンプト（明確な変換ルール）
   - 検証コマンド（npm test 等）
3. dry-run時の出力確認 → 全量実行

## 注意

- fan-outは Rate Limit に注意。Anthropic / OpenAI / Google それぞれ上限あり
- 100ファイル超えるなら `-p` で並列度を 2 程度に下げる
- 失敗したファイルの修復に手作業が必要なケースは多い。完全自動化を期待しない
