# Infrastructure (IaC)

> Terraform / CloudFormation / Helm / Kustomize 等のインフラコード。**applyで本番事故が起きやすい**領域。

## 不変則

- `terraform apply` は **必ずplanをレビュー後**。CI/CDでもplan→人間承認→apply
- リソース削除を含むplanは Slackに通知 + 二人承認
- IAM/RBAC変更はsecurity-advisor必須レビュー
- secret類はTerraform stateに含めない（AWS Secrets Manager / SOPS / Vault）

## ディレクトリ構造

```
infra/
├── modules/        # 再利用可能なモジュール
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/       # 編集時はprincipal-advisorに相談
├── policies/       # OPA / Sentinel ポリシー
└── scripts/        # 単発スクリプト（CIで実行されないもの）
```

## 命名

- リソース: `<env>-<service>-<resource>` 例: `prod-api-rds-primary`
- タグ: `Env`, `Service`, `Owner`, `CostCenter` を必須
- modules: 動詞でなく名詞（`s3-bucket-secure` ✓ / `create-bucket` ✗）

## terraform 規約

- `terraform fmt` を pre-commit で強制
- `tflint` + `tfsec` をCIで実行
- `state lock` 必須（S3 + DynamoDB lock table）
- workspace ではなく env別ディレクトリで分離
- moduleバージョンは ピン留め（`source = "git::...?ref=v1.2.3"`）

## 禁則

- `count = var.enabled ? 1 : 0` パターン禁止 → `for_each` 使用
- ハードコードされたAMI ID / アカウントID → variableに切り出し
- `local-exec` provisioner禁止（再現性なし）
- depends_on の濫用 → 明示参照で表現

## コスト管理

- 新規リソース追加時は cost-advisor レビュー必須（advisorsパック）
- `infracost` をPRに自動投稿
- 月次のreserved instance / savings plan見直しサイクル

## 災害復旧

- バックアップは別リージョン
- RTO/RPO目標を `infra/dr/README.md` に明記
- `terraform destroy` の使用は dev/staging のみ。prodは絶対に書かない

## 削除手順

リソース削除時は以下を順守:
1. PRで削除提案（reasoningを書く）
2. `terraform plan -destroy` を確認
3. ステージングで先に削除して動作確認
4. プロダクション削除前に最終バックアップ
5. 削除後30日は復旧可能な状態を維持（snapshot等）
