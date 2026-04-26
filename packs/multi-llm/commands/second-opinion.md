---
description: Geminiまたは Codexからセカンドオピニオンを取る（軽量）
argument-hint: [gemini|codex] [質問内容]
---

$ARGUMENTS から最初の単語を取り出してLLM選択、残りを質問とする。

# 動作

```
/second-opinion gemini この実装の代替案を提案して
```
↓
gemini-advisor subagent を起動して質問を投げる。

```
/second-opinion codex このアルゴリズムを最適化して
```
↓
codex-advisor subagent を起動して質問を投げる。

# 用途

- Claudeで詰まった時の別視点
- 重要判断の前の確認
- 1 LLMだとコストが心配な時の片方だけ呼ぶケース

# クロスレビューとの違い

- `/cross-review` は3 LLM並列＋集約（重い、確実）
- `/second-opinion` は1 LLMのみ（軽い、速い）
