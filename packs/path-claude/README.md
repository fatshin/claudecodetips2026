# Pack: パス別CLAUDE.md

## 結論

サブディレクトリ別の規約を `<dir>/CLAUDE.md` に置くと、Claude Codeはそのディレクトリで作業する時だけ追加で読む。**ルートCLAUDE.mdが肥大化しないようにスコープで分割する**のが目的。

## 配置

```bash
# 例: TypeScriptの典型的なリポジトリへ
cp packs/path-claude/src-billing-CLAUDE.md  src/billing/CLAUDE.md
cp packs/path-claude/src-auth-CLAUDE.md     src/auth/CLAUDE.md
cp packs/path-claude/tests-CLAUDE.md        tests/CLAUDE.md
cp packs/path-claude/infra-CLAUDE.md        infra/CLAUDE.md
```

## 設計原則

| 種別 | ルートに書く | サブに書く |
|---|---|---|
| 全体規約（命名、Build/Test、コミット） | ✓ | ✗ |
| 全体的な禁則事項 | ✓ | ✗ |
| 特定モジュールの不変則 | ✗ | ✓ |
| 過去のインシデント | 全社的なもの | モジュール固有 |
| 必須レビュアー | ✗ | ✓ |

## /compact後の挙動に注意

公式ドキュメント（および過去のissue）によれば、`/compact` 実行後に **サブディレクトリのCLAUDE.mdが再読込されない場合がある**。重要な規約は明示的に再読込指示を出すか、ルートCLAUDE.mdから `@./src/billing/CLAUDE.md` 形式で参照する運用が安全。

## 棚卸し

3か月に1回、以下のチェックを：

```bash
# パス別CLAUDE.md一覧
find . -name CLAUDE.md -not -path './node_modules/*'

# 最終更新日
find . -name CLAUDE.md -not -path './node_modules/*' -exec ls -la {} \;

# 廃止された機能のCLAUDE.mdが残ってないか
git log --diff-filter=D --name-only -- '**/CLAUDE.md'
```

不要になったルールは削除する（同じ重要度で「削る勇気」も持つ）。
