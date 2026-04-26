# Billing Module

> 課金・決済・サブスクリプション関連。**金額・税・通貨**の取扱でミスると即座に金銭事故になる領域。慎重に。

## 不変則（破ったらコミット拒否）

- 金額は **整数のminor unit**（円なら銭単位ではなく円、USDならcent）。Float禁止。
- 税計算は専用関数 `src/billing/tax.ts` 経由のみ。各所での独自計算禁止。
- 通貨換算は1リクエスト内で一貫したレートを使う。逐次取得禁止。
- 失敗時の補償処理（compensation）は必須。Stripe等の外部はidempotency key必ず付与。

## 命名

- 金額変数: `amountInJpy`, `amountInCents`（単位を変数名に必ず）
- 税: `taxInclusive` / `taxExclusive` を区別して命名
- 期間: `monthlyFee` / `annualFee`、`prorated*` の prefix

## テスト前提

- 通貨ごとの境界値テスト必須（0円、1円、`Number.MAX_SAFE_INTEGER`、負数）
- タイムゾーン: 日本顧客は Asia/Tokyo、グローバルは UTC固定。境界をまたぐ請求書発行のテスト必須。
- 冪等性テスト: 同一idempotency keyで複数回呼んで同じ結果になること。

## 外部連携

| サービス | 用途 | 公式SDK | エラーハンドリング |
|---|---|---|---|
| Stripe | 決済 | `stripe-node` | `StripeIdempotencyError` を必ず捕捉 |
| Adyen | 決済（海外） | `@adyen/api-library` | リトライ最大3回・指数バックオフ |
| 内製会計 | 請求書発行 | `src/billing/internal-accounting.ts` | 失敗時はDLQへ |

## 危険な操作

- マイグレーションでの金額型変更（DECIMAL→BIGINT等）は **必ず up/down 両方** + 並行運用期間を設ける
- 既存請求書の再計算は別ジョブで非同期化。同期で打つと顧客に重複請求される
- リファンドは `src/billing/refund.ts` 経由のみ。Stripe Dashboardからの手動操作は禁止

## レビュー必須項目

このディレクトリへのPRは **principal-advisor + security-advisor** の二重レビュー必須（advisorsパック参照）。

## 過去のインシデント（学習）

- 2024-Qx: 月跨ぎprorationでタイムゾーンを取り違え、約120件で多重請求 → JST固定化
- 2025-Qx: idempotency key忘れでバッチ再実行時に二重課金 → CIで grep して必須化
