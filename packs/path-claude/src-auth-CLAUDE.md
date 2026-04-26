# Auth Module

> 認証・認可・セッション管理。**ここで穴を開けると全機能が陥落**する。実装前に security-advisor 起動必須。

## 不変則

- パスワードは **bcrypt cost ≥ 12** または **Argon2id**。MD5/SHA1禁止。
- セッションIDは `crypto.randomBytes(32)` 以上のエントロピー。連番禁止。
- JWT を使うなら `alg: none` 拒否、`HS256`なら強い秘密鍵、`RS256`推奨。
- トークンは **HttpOnly + Secure + SameSite=Lax/Strict** の Cookie か、ローカルではメモリのみ。LocalStorage禁止。
- Authorizationヘッダー以外で認証情報を渡さない（URL parameter禁止）。

## 命名

- ユーザー識別: `userId` (UUID), `userPublicId`（外部公開可能）と区別
- トークン種別: `accessToken`, `refreshToken`, `idToken`, `apiKey` を混同しない
- 期限: `expiresAtMs` のように単位明記

## テスト前提

- 不正トークン拒否（改竄、署名違い、期限切れ、重複利用）の網羅
- レート制限の動作確認（5回失敗で15分ロック等）
- 並行ログインの取扱（旧セッション破棄するか保持か）
- パスワードリセットのトークン漏洩シナリオ

## 認可

- **必ず関数の入口で実施**。コントローラーで判定→サービス層で生業務処理。
- Role-based or Attribute-based を統一。混在禁止。
- スーパーユーザー権限の利用は監査ログ必須（`auditLogger.warn` でWARNレベル）

## ログ

- 認証情報は **絶対にログ出力しない**（パスワード、トークン、Cookie）
- 失敗ログは `userId` ではなく `userPublicId` または ハッシュ化IDで
- 成功ログも IP・UA・タイムスタンプは残すが、機微情報は伏字

## 外部連携

| サービス | 用途 | 注意 |
|---|---|---|
| Auth0 / Cognito | IdP | refresh token rotationを必ず有効化 |
| Google/Apple SSO | OAuth | state パラメータでCSRF対策必須 |
| TOTP（2FA） | MFA | 時刻ずれ ±30秒以内のみ許容 |

## レビュー必須項目

このディレクトリへのPRは **security-advisor** レビュー必須。
脆弱性スキャナ（Semgrep, Snyk）も CI で自動実行。

## 禁則事項

- パスワード平文保存
- セッションIDを URL パラメータに含める
- CORS の `Access-Control-Allow-Origin: *` + `Allow-Credentials: true` の組合せ
- "テスト用" のバックドアアカウント作成
