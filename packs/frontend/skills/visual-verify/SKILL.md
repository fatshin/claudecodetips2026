---
name: visual-verify
description: UI実装後にスクショを撮って視覚的に確認する。「UI壊れてない？」「見た目どう？」「スクショ撮って」で発火。Chrome拡張が使えればそれを優先、無ければPlaywrightで撮影。
---

# Visual Verification

## 適用判定

以下を含む依頼で発火:
- 「UI/見た目/レイアウト確認」
- 「スクショ取って」
- 「localhost:NNNN を開いて」
- フロントエンドファイル（.tsx/.jsx/.vue/.html/.css）の編集直後

## 手順

### 1. 前提確認
- dev server起動: `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000`
- 200/300系なら続行、それ以外なら起動を促す

### 2. 撮影方式の選択

**Claude in Chrome 拡張が利用可能な場合**（推奨）:
```
/chrome 接続済 → 直接URLを開いてスクショ
> open localhost:3000 and screenshot fullPage
```

**Chrome拡張が無い場合（WSL/Bedrock経由など）**:
```bash
bash scripts/screenshot.sh http://localhost:3000 docs/screenshots/home.png
bash scripts/screenshot.sh http://localhost:3000/login docs/screenshots/login.png
bash scripts/screenshot.sh http://localhost:3000 docs/screenshots/home-mobile.png "375,667" mobile
```

### 3. ビューポート

最低でも以下を撮影:
- desktop（1280×800）
- mobile（iPhone 13 / 375×667）

レスポンシブ対応の場合はtablet（768×1024）も追加。

### 4. 比較（任意）

main branchとの差分を見たい場合:

```bash
# main branchのスクショ取得
git stash
git checkout main
npm run dev &
sleep 5
bash scripts/screenshot.sh http://localhost:3000 /tmp/baseline-home.png
kill %1
git checkout -
git stash pop
npm run dev &
sleep 5
bash scripts/screenshot.sh http://localhost:3000 /tmp/feature-home.png

# 差分確認（ImageMagick使用）
compare -metric AE /tmp/baseline-home.png /tmp/feature-home.png /tmp/diff.png
```

### 5. 出力

```markdown
## Visual Verification

### 撮影結果
- desktop: docs/screenshots/<branch>/home-desktop.png
- mobile: docs/screenshots/<branch>/home-mobile.png

### console errors
- ✓ なし
- または: <検出されたエラー>

### 差分（main比較した場合）
- diff pixels: NNN
- 主な変更箇所: ヘッダー高さ、ボタン配置等

### 所見
- 意図した変更が反映されている: ✓
- 想定外のレイアウト崩れ: なし
- mobileで見切れ: なし
```

## 禁則事項

- スクショを撮って終わりにしない。**必ず内容を見て**問題ないか確認すること
- console error が出ていたら無視せず報告
- screenshot保存先は `docs/screenshots/` または一時的に `/tmp/` を使い、コミットしない
