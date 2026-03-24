# Design: Claude Code 通知クリックでペーンフォーカス

**Date:** 2026-03-24
**Status:** Approved

## 概要

Claude Code が承認待ちになったとき、macOS のデスクトップ通知をクリックすると Ghostty を前面に出し、Claude が動いている tmux ペーンにテレポートする。`alerter` を使うことで通知から直接 Yes/No 承認も可能にする。

## 要件

- macOS システム通知をクリックしたら Ghostty + 該当 tmux ペーンがアクティブになる
- 複数の Claude セッションが同時に動いていても正しいペーンにフォーカスする
- 通知から直接 Yes/No を選んで承認・拒否できる（alerter）
- 既存の Bark 通知（スマホ）はそのまま維持する
- alerter 未インストール時は osascript にフォールバック（テレポートなし）

## 依存ツール

| ツール | 用途 | インストール |
|---|---|---|
| `alerter` | アクションボタン付き通知、クリック結果の取得 | `brew install vjeantet/tap/alerter` |
| `jq` | JSON パース | 既存 |
| `tmux` | ペーンフォーカス | 既存 |

## アーキテクチャ

```
[Claude フック実行時 - permission_prompt]
  $TMUX_PANE, $TMUX, $__CFBundleIdentifier 取得
  tmux ペーンのスナップショットから選択肢を抽出
       ↓
  perm-notify.sh
       ↓ (nohup でデタッチ)
  alerter --title ... --actions "1: Yes, 2: No, ..."
       ↓ (ユーザーのアクションを待機)
  [番号選択] → tmux send-keys で数字を送信
  [本体クリック] → open -b com.mitchellh.ghostty
                   tmux switch-client → select-window → select-pane
  [Dismiss/@TIMEOUT] → 何もしない

[PreToolUse - 全ツール]
  stash_command.sh
       ↓
  /tmp/ccnotifs/cmd_<pane_id> にツール名・コマンドを保存
  （通知の本文に表示するため）
```

## コンポーネント

### `config/claude/hooks/perm-notify.sh`

ccnotifs の `notify.sh` をベースにした通知スクリプト。主な処理：

1. tmux セッション・ウィンドウ・ペーン情報を取得（サブタイトルに表示）
2. stash ファイルから実行予定のツール名・コマンドを読み込む（本文に表示）
3. tmux ペーンのスナップショットを撮り、番号付き選択肢を抽出
4. 既にそのペーンを見ている場合は通知をスキップ（suppression）
5. `alerter` でアクションボタン付き通知を送信（デタッチ実行）
6. alerter の結果に応じてテレポートまたは tmux send-keys

### `config/claude/hooks/stash_command.sh`

PreToolUse で毎回実行。`/tmp/ccnotifs/cmd_<pane_id>` にツール名とコマンドを保存する。

### `Brewfile`

```
brew "vjeantet/tap/alerter"
```

### `settings.json` の変更点

```diff
  "Notification": [
-   {
-     "matcher": "permission_prompt",
-     "hooks": [{"type": "command", "command": "osascript -e 'display notification ...'"}]
-   },
+   {
+     "matcher": "permission_prompt",
+     "hooks": [{"type": "command", "command": "~/.claude/hooks/perm-notify.sh"}]
+   },
    {
      "matcher": "permission_prompt|idle_prompt|elicitation_dialog",
      "hooks": [{"type": "command", "command": "~/.claude/hooks/bark-notify.sh"}]
    }
  ],
+ "PreToolUse": [
+   ... (既存フック維持),
+   {
+     "matcher": "",
+     "hooks": [{"type": "command", "command": "~/.claude/hooks/stash_command.sh"}]
+   }
+ ]
```

## ペーン ID の取り扱い（複数セッション対応）

`$TMUX_PANE`（例: `%3`）は tmux 全体でグローバルにユニーク。各通知の alerter worker に環境変数として渡すため、複数セッションが同時に通知を出しても正しいペーンにテレポートできる。

## フォールバック

```
alerter インストール済み  →  アクションボタン付き通知 + テレポート
alerter なし             →  osascript による通知のみ（テレポートなし）
tmux 外で起動           →  Ghostty activate のみ（ペーンフォーカスなし）
```

## 変更しないもの

- `bark-notify.sh`（スマホへの Bark 通知）
- 他の全フック（PostToolUse, SessionStart, PreToolUse 既存分）
