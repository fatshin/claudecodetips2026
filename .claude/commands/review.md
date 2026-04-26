---
description: 直近の変更をcode-reviewer subagentでレビュー
argument-hint: [対象ブランチ or コミットハッシュ（任意、デフォルトはHEAD）]
---

直近の変更をレビューする。対象: ${ARGUMENTS:-HEAD}

# 手順
1. `git diff ${ARGUMENTS:-HEAD~1}..${ARGUMENTS:-HEAD}` で差分を確認
2. **code-reviewer subagent** を呼んで以下を依頼:
   - 上記差分の重大度別レビュー
   - Critical/Major/Minor の3段階で報告
   - 修正案を擬似コードで添える

3. レビュー結果を要約して提示
4. ユーザーの判断で修正に入るかPRに進むか決定
