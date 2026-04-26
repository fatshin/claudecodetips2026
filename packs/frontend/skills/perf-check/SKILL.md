---
name: perf-check
description: Performance測定（Core Web Vitals: LCP/CLS/INP）。Lighthouse CIで継続監視・回帰検出。「Lighthouse」「パフォーマンス」「Core Web Vitals」で発火。
---

# Performance Check

## 適用判定

以下で発火:
- 「Lighthouse / パフォーマンス / Core Web Vitals」
- 「LCP / CLS / INP / TBT」
- 「サイト遅い」「ボトルネック」
- リリース前の最終チェック

## 主要メトリクス（Core Web Vitals）

| メトリクス | 閾値 | 測定 |
|---|---|---|
| **LCP** (Largest Contentful Paint) | < 2.5s | 主要コンテンツ表示時間 |
| **CLS** (Cumulative Layout Shift) | < 0.1 | レイアウトシフト累積 |
| **INP** (Interaction to Next Paint) | < 200ms | インタラクション応答性（旧FID） |
| TBT (Total Blocking Time) | < 200ms | INPの代理メトリクス（Lab） |
| FCP (First Contentful Paint) | < 1.8s | 初回描画 |

INPはフィールドデータが必要。Lab測定では TBT が代理指標。

## 手順

### 1. シングル測定

```bash
# Performanceのみ
bash scripts/lighthouse-check.sh http://localhost:3000 perf

# 全カテゴリ
bash scripts/lighthouse-check.sh http://localhost:3000 all
```

スコアと Core Web Vitals が表示される。

### 2. 複数回測定（推奨）

Lighthouseは実行ごとに数値ぶれる。**3〜5回平均**を取るのが原則:

```bash
for i in 1 2 3 4 5; do
  bash scripts/lighthouse-check.sh http://localhost:3000 perf
done
ls lighthouse-reports/lighthouse-performance-* | head -5 | \
  xargs -I {} jq '.audits["largest-contentful-paint"].numericValue' {}
# 中央値を採用
```

### 3. CI連携（@lhci/cli）

`lighthouserc.js` 配置:

```js
module.exports = {
  ci: {
    collect: {
      url: ['http://localhost:3000', 'http://localhost:3000/login'],
      numberOfRuns: 3,
      startServerCommand: 'npm run start',
      startServerReadyPattern: 'ready',
    },
    assert: {
      assertions: {
        'categories:performance': ['error', { minScore: 0.85 }],
        'categories:accessibility': ['error', { minScore: 0.90 }],
        'categories:best-practices': ['warn', { minScore: 0.85 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
        'total-blocking-time': ['error', { maxNumericValue: 200 }],
      },
    },
    upload: { target: 'temporary-public-storage' },
  },
};
```

GitHub Actions:

```yaml
- run: npm install -g @lhci/cli
- run: lhci autorun
  env:
    LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}
```

PR毎にスコア比較・回帰検出。

### 4. ボトルネック特定

スコア低い時の調査順:

```bash
# 1. 詳細レポート（HTML形式）
bash scripts/lighthouse-check.sh http://localhost:3000 perf html
open lighthouse-reports/lighthouse-performance-*.html

# 2. opportunities セクションから上位3つ取得
jq '.audits | to_entries | map(select(.value.details.type == "opportunity")) | sort_by(-.value.details.overallSavingsMs) | .[:3] | .[] | {id: .key, savings: .value.details.overallSavingsMs, description: .value.title}' lighthouse-reports/*.json
```

### 5. 主要な改善パターン

| 症状 | 原因 | 対策 |
|---|---|---|
| LCP遅い | 画像・フォント | next/imageでoptimization、preload critical fonts |
| CLS悪い | 画像/iframeのwidth/height欠如、動的挿入広告 | 全imgにaspect-ratio、placeholder確保 |
| TBT高い | JS実行時間 | code splitting、動的import、third-partyスクリプト遅延 |
| FCP遅い | server-side レンダリング遅延 | TTFB改善、CDN、SSG/ISR |

## 出力フォーマット

```markdown
## Performance Check

### スコア（n=3 中央値）
- Performance: 82/100 (target: 85+)
- LCP: 2.3s ✓ (target: <2.5s)
- CLS: 0.15 ✗ (target: <0.1)
- TBT: 180ms ✓ (target: <200ms)
- FCP: 1.2s ✓
- Speed Index: 2.8s

### 改善余地（上位3つ）
1. CLSが0.1超: ヘッダーロゴで遅延shift（aspect-ratio設定で解決）
2. JSバンドル300KB過大: lodash全import → 個別import
3. CDNキャッシュ未設定: Cache-Control 1年化

### 推奨アクション
- 即対応: ヘッダーロゴaspect-ratio追加 (CLS 0.15 → 0.05想定)
- 中期: lodash個別import (JS-50KB、TBT-30ms想定)
- 後続: Cache-Control設定（FCP-200ms想定）

### 測定環境
- Lighthouse: 12.x
- Chrome: <version>
- 測定回数: 3
- ネットワーク: simulated 4G (デフォルト)
```

## 禁則事項

- 1回の測定だけで結論出さない（ぶれが大きい）
- localhost と本番でスコア大きく違う点に注意（CDN/HTTPS差）
- 「スコアだけ追う」アンチパターン: 特定monitor回避のためにユーザー体験を犠牲にしない
