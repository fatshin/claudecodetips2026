---
description: 直近の会話から学習事項を抽出してCLAUDE.mdに追記
argument-hint: [追記したい教訓（任意）]
---

直近の会話で学んだこと（または引数で指示された内容）をCLAUDE.mdに追記する。

# ルール
1. 引数があればその内容を、なければ直近で発生したミス・指摘を抽出
2. **既存のCLAUDE.mdに同じルールがないか確認**してから追記（重複禁止）
3. 追記するセクションを判断（## Conventions / ## Pitfalls / ## Build & Test 等）
4. 1ルール1〜2行で簡潔に。長文禁止。
5. 局所的な事情を全体ルールに昇格させすぎない。`src/billing/CLAUDE.md` のようなパス別CLAUDE.mdへ降ろすことも検討。

# 出力例
```markdown
## Pitfalls
- src/auth ではsession idをログに出さない（PII漏洩懸念）
- DBマイグレーションは必ず up/down 両方を書く
```

# 棚卸し
追記後、CLAUDE.md全体を一度眺めて、不要になった古いルールがあれば削除候補として提示する。
