# Tests

## 構造

- AAA（Arrange / Act / Assert）を守る。`// Arrange` 等のコメントで明示
- 1テスト1観点。複数のExpectを混ぜない（fixtureとhelper活用）
- ファイル名は `<対象>.test.ts` または `<対象>_test.py`、対応元と1:1

## 命名

- describe: 対象クラス/関数名（`describe('UserService', ...)`）
- it: 期待動作を主語動詞で（`it('returns null when userId is empty', ...)`）
- 日本語OKだが、CIログで読めるかだけ確認

## カバレッジ

- 新規コード：行カバレッジ80%以上、分岐カバレッジ70%以上
- 既存にテスト追加するときは、その関数のカバレッジを下げない
- `coverage:` ラベル付きPRは差分カバレッジで判定

## 禁則

- `setTimeout` で待つテスト禁止 → fakeTimers / `vi.useFakeTimers` 等使用
- 外部HTTP実行禁止 → MSW / nock / responses でモック
- 本番DB接続禁止 → テスト用DBコンテナ（testcontainers）
- ランダム値の固定なし禁止 → `Math.random` モック or seed固定

## 種類別ガイド

### 単体テスト
- I/O無し、3秒以内に1000ケース回る速度を維持
- DBアクセスがあるなら `unit/` ではなく `integration/` へ移動

### 結合テスト
- testcontainersでDB/Redisをdocker起動
- マイグレーションは `beforeAll` で適用、`afterEach` でtruncate
- 並列実行時のテスト分離（Postgres schemaを per-test作成等）

### E2E
- Playwright推奨。Cypressは新規禁止
- スモークテストのみCI実行（フル回帰はnightly）
- screenshotとvideo保存（失敗時のみ）

## フィクスチャ

- `tests/fixtures/` 配下にJSON/SQL/seedを集約
- ハードコード値はテスト間共有のとき定数化（`tests/fixtures/constants.ts`）
- 個人情報を含めない（ダミー名は `taro@example.com` 等）

## レビュー観点

- テストが落ちる→修正でなく「テストを変える」のは原則禁止（要justification）
- skip / xit / `.only` の残骸が無いか
- snapshotテストの差分が説明可能か
