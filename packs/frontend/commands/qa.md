---
description: フロントエンド総合QA（visual + a11y + perf + e2e smoke）
argument-hint: [URL（省略時はlocalhost:3000）]
---

$ARGUMENTS で総合QAを実施。引数なしなら http://localhost:3000

# 動作

**frontend-qa** subagent を起動して並列で4種チェック:

1. `bash scripts/screenshot.sh` - desktop/mobile スクショ
2. `bash scripts/axe-check.sh` - a11y violations
3. `bash scripts/lighthouse-check.sh ... perf` - Performance
4. `bash scripts/e2e-smoke.sh` - 主要動線スモーク

並列実行 → 集約レポート出力。

# 出力

```markdown
## Frontend QA Report

### 結論: 🟢 LGTM / 🟡 Issues / 🔴 Block

### Visual: docs/screenshots/<branch>/
### Accessibility: <スコア>/100, violations: <数>
### Performance: <スコア>/100, LCP/CLS/INP表示
### E2E Smoke: <pass/total>

### 推奨アクション
- Critical: ...
- Major: ...
```

# コスト

- スクショ: 数秒
- a11y: 30〜60秒
- perf (3回): 90〜180秒
- e2e smoke: 30〜60秒
- 合計: 3〜6分

`/ultrareview` ほどではないが重め。重要PR・リリース前のみ推奨。

# 使用例

```
/qa
/qa http://localhost:3000
/qa https://staging.example.com
```
