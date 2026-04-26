---
description: Lighthouse Performance測定（Core Web Vitals）
argument-hint: [URL（省略時はlocalhost:3000）]
---

$ARGUMENTS のパフォーマンス測定。引数なしなら http://localhost:3000

# 動作

1. **perf-check** skill を起動
2. Lighthouse perf を **3回実行**して中央値計算
3. Core Web Vitals 表示:
   - LCP / CLS / INP (TBT) / FCP / Speed Index
4. opportunities 上位3つを抽出
5. 改善案と期待効果を提示

# 使用例

```
/perf
/perf http://localhost:3000/dashboard
/perf https://staging.example.com
```

# 閾値（fail）

- Performance score < 85
- LCP > 2.5s
- CLS > 0.1
- TBT > 200ms

これらに該当したら Block / Request Changes 判定。
