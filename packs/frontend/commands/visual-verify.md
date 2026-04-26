---
description: UI実装後にスクショを撮って視覚的に確認
argument-hint: [URL（省略時はlocalhost:3000）]
---

$ARGUMENTS のスクショを撮って確認する。引数なしなら http://localhost:3000

# 動作

1. **frontend-qa** subagent または **visual-verify** skill を起動
2. dev server起動確認
3. 撮影方式を選択:
   - Claude in Chrome 拡張が利用可能 → `/chrome` 経由でネイティブ撮影
   - 利用不可 → `bash scripts/screenshot.sh`
4. desktop / mobile の2種を撮影
5. console error を確認
6. 結果を `docs/screenshots/<branch>/` に保存
7. 内容を確認して所見をユーザーに返す

# 使用例

```
/visual-verify
/visual-verify http://localhost:3000/login
/visual-verify https://staging.example.com
```
