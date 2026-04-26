# Pack: Frontend QA（Chrome+Lighthouse+axe+e2e）

## 結論

フロントエンド用の **build → verify** ループを完成させるパック。Boris推奨「Claude に検証手段を与える」原則をフロントエンドで実現する。

Claude in Chrome（公式）+ Playwright（fallback）+ Lighthouse + axe-core + E2E smoke を統合。

## 提供物

```
frontend/
├── CHROME-EXTENSION-SETUP.md    # 公式拡張のセットアップ手順
├── agents/
│   └── frontend-qa.md           # 総合QA司令塔
├── skills/
│   ├── visual-verify/SKILL.md   # スクショ確認
│   ├── a11y-check/SKILL.md      # axe + Lighthouse a11y
│   └── perf-check/SKILL.md      # Lighthouse perf + Core Web Vitals
├── hooks/
│   └── post-frontend-edit.sh    # オプトイン: 編集後の軽量チェック
├── scripts/
│   ├── screenshot.sh            # Playwright スクショ
│   ├── lighthouse-check.sh      # Lighthouse CLI ラッパー
│   ├── axe-check.sh             # axe-core CLI ラッパー
│   └── e2e-smoke.sh             # Playwright e2e smoke
└── commands/
    ├── visual-verify.md         # /visual-verify
    ├── a11y.md                  # /a11y
    ├── perf.md                  # /perf
    └── qa.md                    # /qa（4種総合）
```

## セットアップ

### 1. 公式拡張（推奨ルート）

```bash
# Claude in Chrome 拡張インストール
open "https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn"

# Claude Code から接続
claude --chrome
# または既存セッションで /chrome
```

詳細は `CHROME-EXTENSION-SETUP.md` 参照。

### 2. パック統合

```bash
# install-packs.shで一括導入
bash scripts/install-packs.sh --packs frontend

# または手動
cp packs/frontend/agents/*.md         .claude/agents/
cp -r packs/frontend/skills/*         .claude/skills/
cp packs/frontend/commands/*.md       .claude/commands/
mkdir -p scripts
cp packs/frontend/scripts/*.sh        scripts/
chmod +x scripts/screenshot.sh scripts/lighthouse-check.sh \
         scripts/axe-check.sh scripts/e2e-smoke.sh
cp packs/frontend/CHROME-EXTENSION-SETUP.md docs/
```

### 3. 必要ツール

```bash
# Node.js（必須、v20+）
node --version

# 各ツールはnpx --yesで自動取得されるが、頻繁に使うなら globalインストール推奨
npm install -g lighthouse @axe-core/cli playwright
npx playwright install chromium

# jq（出力解析用）
brew install jq        # macOS
apt-get install jq     # Linux
```

## 使い方

### スクショ確認（軽量）

```
/visual-verify
/visual-verify http://localhost:3000/login
```

→ `frontend-qa` subagent が起動 → スクショ撮影 → console error確認

### a11y チェック

```
/a11y                                         # localhost:3000
/a11y http://localhost:3000/login
/a11y https://staging.example.com
```

→ axe-core + Lighthouse a11y → impact別violations

### Performance測定

```
/perf
/perf http://localhost:3000/dashboard
```

→ Lighthouse 3回平均 → Core Web Vitals → 改善案

### 総合QA（重め）

```
/qa
/qa https://staging.example.com
```

→ 4種並列実行 → 統合レポート

## Build-Test-Verifyループの完成形

Boris推奨フローをフロントエンド向けに完成させた:

```
1. 実装（Claude Code, terminal）
   ↓
2. dev server起動（npm run dev）
   ↓
3. /visual-verify でスクショ確認
   ↓ レイアウト崩れあり
4. 修正
   ↓
5. /a11y でアクセシビリティチェック
   ↓ violations 検出
6. 修正
   ↓
7. /perf で Core Web Vitals 確認
   ↓ CLS悪化検出
8. 修正
   ↓
9. /qa で総合確認
   ↓ 全部 green
10. /ship でPR作成
```

各ステップで Claude が**自分で検証→修正**するループが回る。

## CI連携

PR毎に自動実行:

```yaml
# .github/workflows/frontend-qa.yml
name: Frontend QA
on: pull_request
jobs:
  qa:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci
      - run: npm run build
      - run: npm run start &
      - run: sleep 10
      
      - run: bash scripts/lighthouse-check.sh http://localhost:3000 all
      - run: bash scripts/axe-check.sh http://localhost:3000 wcag21aa json
      - run: bash scripts/e2e-smoke.sh
      
      - uses: actions/upload-artifact@v4
        with:
          name: qa-reports
          path: |
            lighthouse-reports/
            axe-reports/
            e2e-reports/
```

## トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| Playwright起動失敗 | chromium未インストール | `npx playwright install chromium` |
| Lighthouseがheadless失敗 | CI環境のsandbox | `--chrome-flags="--no-sandbox"` 既に設定済 |
| axe `command not found` | npm install失敗 | `npx @axe-core/cli` で代替 |
| dev serverに接続できない | ポート未起動 / 別ポート | `BASE_URL=http://localhost:5173 bash scripts/...` |

## Chrome拡張 vs Playwright 使い分け

| 状況 | 推奨 |
|---|---|
| ログイン状態を共有したい | Chrome拡張 |
| ローカル開発で軽量 | Chrome拡張 |
| CI環境（headless必須） | Playwright |
| WSL / Bedrock / Vertex経由 | Playwright |
| ビジュアルregression test | Playwright（screenshotsで比較） |
| インタラクティブな検証 | Chrome拡張 |

## 公式リファレンス

- Claude in Chrome: https://code.claude.com/docs/en/chrome
- Lighthouse CLI: https://github.com/GoogleChrome/lighthouse
- Lighthouse CI: https://github.com/GoogleChrome/lighthouse-ci
- axe-core CLI: https://www.npmjs.com/package/@axe-core/cli
- Playwright: https://playwright.dev/
