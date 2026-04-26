---
name: a11y-check
description: アクセシビリティ（WCAG 2.1 AA準拠）チェック。axe-core + Lighthouse でviolations検出して修正提案を出す。「a11y」「アクセシビリティ」「WCAG」で発火。
---

# Accessibility Check

## 適用判定

以下を含む依頼で発火:
- 「アクセシビリティ / a11y / WCAG」
- 「スクリーンリーダー対応」
- 「キーボード操作」
- フロントエンドの本格レビュー前

## 検査ツール

| ツール | 強み | 弱み | 用途 |
|---|---|---|---|
| **axe-core** | 詳細なviolation情報、CI連携◯ | 実行時間やや長 | 本格チェック |
| **Lighthouse a11y** | スコア化、トレンド追跡可 | 細かい違反は見逃す | スコア管理・概観 |
| **手動チェック** | キーボード操作、スクリーンリーダー実機 | 自動化不可 | 最終確認 |

3つを組み合わせて使う。**自動ツールでは全violations の約3分の1しか検出できない**ことを認識した上で。

## 手順

### 1. URL確認

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
```

### 2. axe-core 実行

```bash
bash scripts/axe-check.sh http://localhost:3000 wcag21aa json
```

出力: `./axe-reports/axe-<TS>.json` + console summary

### 3. Lighthouse a11y 実行

```bash
bash scripts/lighthouse-check.sh http://localhost:3000 a11y
```

出力: `./lighthouse-reports/lighthouse-accessibility-<TS>.json`

### 4. 結果集約

axe violations を impact 別に分類:

| impact | 対応方針 |
|---|---|
| **critical** | 即修正、マージブロック |
| **serious** | 修正推奨、別PRも可 |
| **moderate** | 後続issueでOK |
| **minor** | 認知のみ |

Lighthouse score の閾値:
- 95+ → 優秀
- 90〜94 → OK
- 80〜89 → 改善余地大
- <80 → 要改善

### 5. 修正提案の出力

```markdown
## Accessibility Check

### スコア
- Lighthouse a11y: XX/100
- axe violations: N件 (critical: X, serious: Y, moderate: Z, minor: W)

### Critical/Serious violations

#### #1: [rule-id] color-contrast
- 該当: [file:line]
- 内容: 文字色と背景色のコントラスト比が 4.5:1 未満
- 該当箇所:
  ```html
  <span class="text-gray-400 bg-white">注意</span>
  ```
- 計測値: 2.85:1
- 必要値: 4.5:1 (normal text) / 3:1 (large text)
- 修正案:
  ```html
  <span class="text-gray-700 bg-white">注意</span>  <!-- 7.5:1 -->
  ```
- WCAG: 1.4.3 Contrast (Minimum)
- 参考: https://dequeuniversity.com/rules/axe/4.7/color-contrast

#### #2: [rule-id] aria-required-attr
（同様）

### 手動確認推奨項目（自動では検出不可）

- [ ] Tab/Shift+Tabで全インタラクティブ要素を辿れる
- [ ] フォーカスインジケータが視認できる
- [ ] モーダル開時にfocus trapあり、Esc閉じできる
- [ ] エラーメッセージがスクリーンリーダーに通知される
- [ ] 画像のalt属性が文脈に沿っている
- [ ] 動画に字幕がある（該当時）
```

## CI 統合（推奨）

PRに自動で a11y チェック走らせる:

```yaml
# .github/workflows/a11y-check.yml
name: A11y Check
on: pull_request
jobs:
  a11y:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci && npm run build && npm run start &
      - run: sleep 10
      - run: bash scripts/axe-check.sh http://localhost:3000 wcag21aa json
      - run: bash scripts/lighthouse-check.sh http://localhost:3000 a11y
```

## 禁則事項

- 「とりあえず axe 通った」で終わらせない（自動検出は1/3だけ）
- 「a11y は最後にやる」発想 → 後付けは超高コスト。**実装しながら**
- 警告レベルを下げて violations を減らす偽装行為
- ARIA を増やして「対応した」とする（**ARIAは最終手段**、HTML5 semantic要素優先）
