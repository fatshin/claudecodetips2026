# Pack: Monitoring（Boris Cherny / 公式docs / GitHub releases 監視）

## 結論

Boris Cherny の発信、Claude Code 公式docs、GitHub releases を**週次/月次で自動監視**し、変更を検知したら**Kitへのアップデート提案を Claude が自動生成**して GitHub Issue起票する。

これで「Tipsを覚え続ける」コストを撤廃。**情報が古くなる前にKit自身が指摘してくる**運用に。

## 提供物

```
monitoring/
├── README.md
├── sources.yaml                       # 監視対象URL定義
├── manual-boris-input.md.example      # 手動投入テンプレ
├── scripts/
│   ├── run-monitoring.sh              # マスター実行
│   ├── fetch-releases.sh              # GitHub releases
│   ├── fetch-docs.sh                  # 公式docs
│   ├── fetch-boris.sh                 # Boris発信（複数手段）
│   ├── snapshot-diff.sh               # 前回比較
│   └── analyze-update.sh              # Claude分析
├── workflows/
│   └── monitor-update.yml             # GitHub Actions（週次/月次）
├── commands/
│   └── check-updates.md               # /check-updates（手動trigger）
└── snapshots/                         # 履歴保持（最大90日）
```

## セットアップ

```bash
# 1. パック導入
bash scripts/install-packs.sh --packs monitoring

# 2. 必要ツール
sudo apt-get install -y lynx jq           # Linux
brew install lynx jq                      # macOS
gh auth login                             # GitHub CLI

# 3. 環境変数
export ANTHROPIC_API_KEY="sk-ant-xxx"
export GEMINI_API_KEY="AIzaSy-xxx"        # Boris発言検索に使用（任意）

# 4. 動作確認（手動実行）
bash packs/monitoring/scripts/run-monitoring.sh

# 5. 自動化（GitHub Actions）
# workflows/monitor-update.yml が .github/workflows/ にコピーされている前提
gh secret set ANTHROPIC_API_KEY --body "sk-ant-xxx"
gh secret set GEMINI_API_KEY --body "AIzaSy-xxx"
```

## 監視対象（4ソース）

### 1. GitHub Releases（**最も確実**）

| リポジトリ | 取得方法 | 頻度 |
|---|---|---|
| `anthropics/claude-code` | `gh release list` | 週次 |
| `anthropics/claude-code-action` | `gh release list` | 週次 |
| `anthropics/claude-code-docs`（あれば） | `gh api commits` | 週次 |

API rate limitsの心配なし。スクリプト一発で取れる。

### 2. 公式docs（HTTP fetch）

```
https://code.claude.com/docs/en/overview
https://code.claude.com/docs/en/changelog
https://code.claude.com/docs/en/hooks
https://code.claude.com/docs/en/permissions
https://code.claude.com/docs/en/subagents
https://code.claude.com/docs/en/skills
https://code.claude.com/docs/en/chrome
https://code.claude.com/docs/en/checkpointing
https://www.anthropic.com/news
```

`lynx -dump` または `pandoc` でテキスト化して差分検知。

### 3. Boris Cherny の発信（**取得困難**）

X.com と threads.net は robots.txt で web fetch をブロックしている。**4つの代替手段**を順次試行:

| 手段 | 確実性 | コスト | 設定 |
|---|---|---|---|
| RSS bridge (`rsshub.app`) | 中 | 無料 | self-host推奨 |
| nitter mirror | 低 | 無料 | mirrorは閉鎖が多い |
| Gemini CLI でWeb検索 | 中 | $0.01/回 | GEMINI_API_KEY必要 |
| **手動投入** | 高 | 0 | テンプレに貼るだけ |

実用上は **Gemini検索 + 手動投入の併用** が最も安定。

#### 手動投入の運用

```bash
# テンプレ配置
cp packs/monitoring/manual-boris-input.md.example docs/manual-boris-input.md

# Boris の発言を見つけたら追記
$EDITOR docs/manual-boris-input.md
```

`fetch-boris.sh` は `docs/manual-boris-input.md` があれば自動で取り込む。

### 4. Anthropic公式ブログ

`https://www.anthropic.com/news` のHTML差分。Claude Code関連の記事を検出。

## 実行フロー

```
週次 / 月次 cron
   ↓
fetch-releases.sh ──→ snapshots/<TS>/claude-code-releases.json
fetch-docs.sh     ──→ snapshots/<TS>/docs/*.txt
fetch-boris.sh    ──→ snapshots/<TS>/boris/*.{xml,md}
   ↓
snapshot-diff.sh
   ↓ 差分あり?
   ├── No → 何もしない
   └── Yes
        ↓
       analyze-update.sh
        ↓
        Claude が以下を分析:
        - 検知された主要変化
        - 影響度（高/中/低）
        - 推奨対応タイミング（即時/今四半期/様子見）
        - 自家製パックの公式移行可否
        - 新規取り込み候補
        ↓
       update-proposal.md 生成
        ↓
       GitHub Issue起票（"kit-update,automated" ラベル）
```

## 出力サンプル

`snapshots/<TS>/update-proposal.md`:

```markdown
# Claude Code Kit アップデート提案

## エグゼクティブサマリー
- 検知された主要変化
  1. /loop コマンドが正式リリース（v2.5.0）
  2. PostToolUse hook に新フィールド追加
  3. Boris のThreadsで「Stop hook の長時間運用」発言
- 影響度: 中
- 推奨対応: 今四半期

## 機能別影響分析

### 新機能の検知
| 新機能 | ソース | 状態 | このKitとの関係 |
|---|---|---|---|
| /loop | github release v2.5.0 | GA | research-preview/schedule.md と機能重複 |

### 既存機能の変更
| 機能 | 変更内容 | 該当ファイル | 修正必要性 |
|---|---|---|---|
| PostToolUse hook | matcher field拡張 | .claude/settings.json | 中（後方互換あり） |

## 自家製パックの公式移行可否

| 自家製機能 | 公式版 | 移行推奨度 | 備考 |
|---|---|---|---|
| /schedule | /loop GA | 🟢 移行推奨 | 公式版が高機能 |
| /ultrareview | 公式 /ultrareview Preview | 🟡 様子見 | Preview段階 |
| Routines workflow | /loop で代替可 | 🟡 様子見 | 既存運用継続 |

## 即時対応
- [ ] research-preview/commands/schedule.md に /loop 言及追加
- [ ] CLAUDE.md の "schedule" ガイドを公式 /loop ベースに書換

## 今四半期対応
- [ ] /ultrareview の公式版動作確認
- [ ] 自家製版との比較ベンチマーク
```

## カスタマイズ

### sources.yaml で監視対象追加

```yaml
web:
  - name: my-team-internal-docs
    url: https://docs.your-company.com/claude-code-internal
    enabled: true

github:
  - name: our-fork
    repo: your-org/claude-code-kit-fork
    type: release
    enabled: true
```

### 実行頻度の調整

```yaml
# .github/workflows/monitor-update.yml
on:
  schedule:
    # デフォルト: 週次月曜 + 月次1日
    - cron: '0 1 * * 1'
    - cron: '0 0 1 * *'
    
    # 例: 日次にしたい場合
    # - cron: '0 0 * * *'
    
    # 例: 月次のみ
    # - cron: '0 0 1 * *'
```

### 通知チャネル

デフォルトは GitHub Issue。Slackに通知したい場合:

```yaml
# workflowの最後に追加
- name: Notify Slack
  uses: slackapi/slack-github-action@v1.27.0
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "Claude Code Kit にアップデート提案: ${{ steps.snapshot.outputs.dir }}/update-proposal.md"
      }
```

## トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| `fetch-boris.sh` が空 | rsshub/nitter全閉鎖 | 手動投入運用に切替 |
| `lynx not found` | 未インストール | `apt install lynx` / `brew install lynx` |
| GitHub Actions失敗 | Secrets未設定 | ANTHROPIC_API_KEY / GEMINI_API_KEY 確認 |
| diff が常に "変更なし" | 初回snapshotがない | 一度手動実行してbaseline作成 |
| Issue大量起票 | 閾値（50字）が低い | scripts/snapshot-diff.sh で `DIFF_SIZE > 200` を増やす |
| Claude分析が無関係な提案 | プロンプトの問題 | scripts/analyze-update.sh のPROMPTを調整 |

## コスト

| 項目 | 月次コスト |
|---|---|
| GitHub Actions（週次+月次=月5実行） | 〜$0.05（Free tier内） |
| Claude API（分析） | $0.50〜$2.00 |
| Gemini API（Boris検索） | $0.05〜$0.20 |
| **合計** | **月 $0.60〜$2.30** |

## 自動化のリスクと対策

### リスク1: 過剰な提案で疲弊

**対策**: Issue起票の閾値（diff size、変更頻度）を厳しめにする。週次→月次に戻す。

### リスク2: 誤った提案を信じてKitを壊す

**対策**: 提案は **必ず人間レビュー** してからマージ。Issueテンプレに「アクションアイテム」確認欄を含む。

### リスク3: API key漏洩

**対策**: GitHub Secrets経由でのみ提供。snapshotにkeyが混入しないよう scripts内でも露出禁止。

### リスク4: snapshotサイズ肥大

**対策**: 90日retention。`fetch-docs.sh` のテキスト化で容量削減。`_diff` ディレクトリは即時消す運用も検討。

## 公式機能との置き換え

将来的にAnthropic自身が「Kit update suggestions」を公式提供したら、本パックは廃止候補。それまでの繋ぎ。

監視中の動向（`research-preview-watch.md` Issue でtrack）。
