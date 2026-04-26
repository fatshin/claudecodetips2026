# Pack: MCP設定（Dify/Bedrock/GitHub/Slack）

## 結論

`mcp.json` をプロジェクトルートに `.mcp.json` として配置し、`.env.local` に各APIキーを入れる。Claude Codeが起動時に自動読込する。

## セットアップ

```bash
# 1. ファイル配置
cp packs/mcp/mcp.json .mcp.json
cp packs/mcp/.env.example .env.local

# 2. APIキー入力
$EDITOR .env.local

# 3. .gitignoreに.env.localが入っているか確認
grep -q '^\.env\.local$' .gitignore || echo '.env.local' >> .gitignore

# 4. Claude Code起動して確認
claude
> /mcp                 # 接続済MCPサーバー一覧
> /mcp list-tools      # 各サーバーが提供するツール
```

## 各サーバーの用途と前提

### GitHub
- **用途**: Issue/PR/Repo操作。「@claude このIssue実装して」フローのバックエンド。
- **前提**: PATまたはGitHub Apps連携。fine-grained PAT推奨。
- **公式**: https://github.com/modelcontextprotocol/servers/tree/main/src/github

### Slack
- **用途**: チャンネル監視、リリース通知、障害共有の自動化。
- **前提**: Slack App作成 → Bot Token取得 → 必要chに招待。
- **公式**: https://github.com/modelcontextprotocol/servers/tree/main/src/slack

### AWS Bedrock
- **用途**: Bedrock Knowledge Basesへのクエリ、Foundation Models呼出。RAG設計の検証に。
- **前提**: AWS SSOまたはアクセスキー。`aws-mcp` パッケージを `uvx` で取得。
- **代替**: `aws-mcp-bedrock-runtime`、または公式 `@aws/mcp-server-bedrock`（出てれば）
- **公式**: https://github.com/awslabs/mcp

### Dify
- **用途**: Dify Workflow/AgentをClaude Codeのツールとして呼ぶ。RAG / カスタムAgent統合。
- **前提**: Dify Self-hosted または Cloud。各WorkflowのAPIキー取得。
- **代替実装**: 自前で `dify-api-mcp-server` を書くのも有効（DifyのOpenAPI仕様が公開されている）。

### Filesystem / Postgres
- **用途**: プロジェクト外資料の参照、開発DBの調査。
- **注意**: 本番DBは絶対に接続しない。read-onlyロール必須。

## 動作確認

```bash
claude
> /mcp                                             # サーバー接続状況
> 「最近の自分宛GitHub Issueを5件取ってきて」      # github MCPテスト
> 「#dev-alerts チャンネルの直近10メッセージを要約」 # slack MCPテスト
> 「Bedrock KB から ARI 部門の社内ドキュメント検索」 # bedrock MCPテスト
> 「Dify の SOMPO問合せ削減Workflow を呼んで」     # dify MCPテスト
```

## トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| `/mcp` で表示されない | 環境変数未読込 | `direnv allow` または `source .env.local` |
| 認証エラー | トークン期限切れ・スコープ不足 | 各サービスのコンソールで再発行 |
| `command not found: uvx` | uv未インストール | `pip install uv` または `brew install uv` |
| Bedrock権限エラー | IAMロール不足 | bedrock:Retrieve, bedrock:RetrieveAndGenerate付与 |

## permissions連携

`.claude/settings.json` でMCPツール単位の制御も可能:

```json
{
  "permissions": {
    "allow": [
      "mcp__github__list_issues",
      "mcp__slack__list_channels"
    ],
    "ask": [
      "mcp__github__create_pull_request",
      "mcp__slack__post_message"
    ],
    "deny": [
      "mcp__postgres__execute"
    ]
  }
}
```

書込系・破壊系は `ask` または `deny` に置くのが原則。
