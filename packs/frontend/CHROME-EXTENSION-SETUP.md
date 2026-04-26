# Claude in Chrome × Claude Code セットアップ

## 結論

**公式機能**として提供されている `Claude in Chrome` 拡張を Claude Code から `--chrome` フラグまたは `/chrome` コマンドで使う。Playwright MCP より高速で、ブラウザのログイン状態を共有できる。

## 前提条件

| 項目 | バージョン | 入手先 |
|---|---|---|
| Claude Code | v2.0.73以上 | `npm install -g @anthropic-ai/claude-code` |
| Claude in Chrome 拡張 | v1.0.36以上 | [Chrome Web Store](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn) |
| ブラウザ | Chrome または Microsoft Edge | - |
| 契約 | Claude Pro/Max/Team/Enterprise（直接Anthropic） | Bedrock/Vertex経由は**非対応** |
| OS | macOS / Linux / Windows | **WSL は非対応** |

## セットアップ

```bash
# 1. Claude Code を最新化
npm install -g @anthropic-ai/claude-code@latest
claude --version  # 2.0.73以上を確認

# 2. Chrome Web Store から拡張インストール
open "https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn"
# Chrome → 「Claude」拡張を「Add to Chrome」
# 拡張アイコンをピン留め（パズルピース→ピン）
# Claude アカウントでサインイン

# 3. Claude Code から接続
claude --chrome
# または既存セッションで:
# /chrome
# → 「Enabled by default」を選択するとデフォルト有効化

# 4. 動作確認
claude --chrome
> open localhost:3000 and tell me if the login form renders correctly
```

## 接続トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| 拡張が検出されない | native messaging host設定未生成 | Chrome再起動して再試行 |
| 接続が長時間後に切れる | service worker idle | `/chrome` → "Reconnect extension" |
| ブラウザイベントが届かない | JavaScript dialog（alert/confirm）がブロック | 手動で閉じてから再開 |
| `EADDRINUSE` | 別Claude Codeセッションが同pipe使用 | 他セッション終了 |

## 代替: Playwright（Chrome拡張が使えない場合）

WSL/Bedrock/Vertex経由など、公式拡張が使えない環境では Playwright で代替可能。本キットの `frontend` パックは両方サポート:

```bash
# Playwright（headless）
bash scripts/screenshot.sh http://localhost:3000

# Chrome拡張使用（推奨、高速、ログイン状態共有）
claude --chrome
> screenshot http://localhost:3000
```

## Boris推奨: Build-Test-Verify ループ

```
1. Claude Code（terminal）で実装
   ↓
2. Claude in Chrome で実機検証
   ↓
3. console.log/network errorをClaudeが直接読む
   ↓
4. エラーがあれば(1)に戻って修正
```

具体例:

```
> ログインフォームのバリデーション修正完了。 
  localhost:3000 開いて、不正なemail入れてエラー表示されるか確認して。
  console errorがあれば原因を特定して直して。
```

→ Claude Code が:
1. localhost:3000 を Chrome で開く
2. invalid emailを入力 → submit
3. エラー表示の有無確認
4. console読込 → 必要なら修正
5. 再実行

## permissions（拡張側）

拡張のオプション → サイト別permissions で:
- 信頼サイトのみ pre-approve
- 危険な操作（購入・削除）は常に確認
- 業務サイトは allowlist 化

Team/Enterprise plan では admin が組織横断で allowlist/blocklist を管理可能。

## 参考: Boris Cherny 公式コメント

> 「Claude Code を使う上で最も重要なTipは、Claude に出力を**検証する手段**を与えること。
> ブラウザを使わせれば、結果が良くなるまで自分で繰り返す。」
> — Boris Cherny ([Threads](https://threads.com/@boris_cherny))

## 公式リファレンス

- セットアップ: https://code.claude.com/docs/en/chrome
- ヘルプ: https://support.claude.com/en/articles/12012173-get-started-with-claude-in-chrome
- 拡張: https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn
