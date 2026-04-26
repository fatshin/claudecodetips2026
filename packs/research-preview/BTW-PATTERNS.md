# `/btw` 活用パターン集

## 結論

`/btw` は**長時間のClaudeタスク実行中に質問・指示を割り込ませる**ための公式コマンド。historyを汚さず、メインタスクの context を維持したまま即座にreplyを得られる。

「ながら聞き」が可能になるので、長時間放置を恐れずに走らせて、必要な時だけ確認する運用を成立させる。

## 基本動作

```
（メインタスク実行中）
> /btw 今のステップどこ？
（tasks継続しつつ即答）
```

公式説明（Boris Cherny）:
> Use `/btw` to ask quick questions while Claude Code is working. No interruption, no history pollution.

## 使う場面パターン

### Pattern 1: Long-running task の進捗確認

```
> 100ファイルのreact class component を hooks に移行して

（30分かかる作業）

> /btw 今何ファイル目？

→ 「現在 47/100。残り推定15分。」（即答、メインタスク継続）
```

### Pattern 2: 進行中の意思決定確認

```
> このRAGアーキの設計を proposal.md にまとめて

（15分の調査・執筆中）

> /btw OpenSearch ServerlessとpgvectorとS3 Vectorsで悩んでるけど、 
       proposal の中で結論出してる？

→ 「まだ各々の比較表セクション執筆中。最終結論は3つ目のtrade-off
    分析後に出します。要望あれば優先順位を変えますが、どうします？」
```

### Pattern 3: 別作業中の補足情報追加

```
> auth/oauth.ts の実装

（実装中）

> /btw Google OAuth に加えて Apple Sign In も対応必要。

→ 「了解。Apple Sign In分はseparate PR にする？それともこのPRに統合？」
```

### Pattern 4: 失敗時の早期発見

```
> npm test の失敗を全部直して

（テスト10個目を直してる途中）

> /btw 5個目の auth.test.ts どう直した？

→ 「mocking部分でJestの cleanups順序を fixした。
    詳細: <要約>。フル diff は終わってから出す。」
```

### Pattern 5: ペース調整

```
> このリポジトリ全体に strict null checks を有効化

（fan-out で大量のファイル直してる）

> /btw 全ファイル Push せず、最初の10ファイル分だけ commit 作って一旦止めて

→ 「了解。あと2ファイル直したらstop して、レビュー用に PR draft 作る。」
```

## メインタスクとの関係

| アクション | 影響 |
|---|---|
| 通常の発話 | history に記録、文脈に影響 |
| `/btw` | history非汚染、メインタスク継続 |
| `Esc` x2 | rewind menu表示（タスク巻き戻し） |
| `Ctrl+C` | タスク強制中断 |

長時間タスクを途中で軌道修正したいなら `/btw`、最初からやり直しなら rewind、止めたければ Ctrl+C。

## 推奨運用

### Long-running を恐れない

`/btw` の存在で、**Claudeに長時間放置で複雑タスクを任せる心理的障壁が下がる**。

```
> このリポジトリ全体のtsconfigをstrict modeに段階有効化して、 
  各フラグごとに別PRを作って、PR毎にCI通るまで自動で直して

（1〜2時間かかる）

# 数十分後、別作業しながら
> /btw 何PR目？

→ 即座に進捗回答
```

### 並列worktreeとの組合せ

複数Claudeセッションを worktree で並走させる時の見回り:

```bash
# tmuxで4 worktree並走中
tmux attach -t cc-1234567890

# 各pane で
> /btw 作業状況を一行で

→ 各セッションから即時返答
→ 注意必要なやつだけ個別に対応
```

## アンチパターン

### ❌ メインタスクと無関係な質問

```
> /btw 今日の天気は？
```

→ context window消費。普通に新セッションで聞くべき。

### ❌ /btw でメインタスクを変更

```
> /btw 上の作業やめて、こっち先にやって
```

→ メインタスクへの指示は普通の発話で。`/btw`は**質問専用**と思った方が安全。

### ❌ 連続乱用

```
> /btw 進捗
（5秒後）
> /btw 進捗  
（5秒後）
> /btw 進捗
```

→ メインタスクが進まない。ある程度の間隔をあけて使う。

## status line との併用

`/btw` で個別質問を投げるのも良いが、**status line（Tip 12）を設定しておくと進捗が常時見える**。両者の使い分け:

| 用途 | 適切なツール |
|---|---|
| 進捗% / 現在のbranch / コスト | status line（常時表示） |
| 質問・補足指示 | /btw |
| ペース変更 | /btw または 通常発話 |

## 公式情報

- Boris Cherny コメント: https://threads.com/@boris_cherny
- 詳細記事: https://wmedia.es/en/tips/btw-questions-while-claude-works
