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

## コンポーネント

### `config/claude/hooks/stash_command.sh`

PreToolUse で毎回実行。Claude Code が stdin に渡す JSON からツール名・コマンドを取り出して一時ファイルに保存する。

**入力（stdin）:**
```json
{"tool_name": "Bash", "tool_input": {"command": "git commit -m ..."}, "cwd": "/..."}
```

**処理:**
```bash
# tmux 外では何もしない
[ -n "${TMUX_PANE:-}" ] || exit 0

INPUT=$(cat)
PANE_ID="${TMUX_PANE#%}"           # "%3" → "3"
TOOL=$(jq -r '.tool_name // ""' <<< "$INPUT")
CMD=$(jq -r '(.tool_input.command // .tool_input.path // "") | .[0:80]' <<< "$INPUT")

mkdir -p /tmp/ccnotifs
printf '%s\t%s\n' "$TOOL" "$CMD" > "/tmp/ccnotifs/cmd_${PANE_ID}"
```

**出力:** `/tmp/ccnotifs/cmd_<PANE_ID>` — タブ区切り 1 行 `"ToolName\tcommand preview"`

複数の PreToolUse が連続した場合は最後のツールで上書きされる（意図的）。

---

### `config/claude/hooks/perm-notify.sh`

Notification フックから呼ばれる。処理をすぐ終えて alerter worker をデタッチ起動する（非ブロッキング）。

#### フロー

```
perm-notify.sh (stdin: JSON)
  │
  ├─ tmux 外 ($TMUX_PANE が空) → osascript フォールバック → exit
  │
  ├─ suppression チェック → 既に見ている → exit 0
  │
  ├─ tmux session / window / pane 情報を収集
  ├─ /tmp/ccnotifs/cmd_<PANE_ID> を読んでツール名・コマンドを取得
  ├─ tmux capture-pane で選択肢を抽出
  ├─ /tmp/ccnotifs/cmd_<PANE_ID> を削除
  │
  ├─ alerter インストール済み?
  │     Yes → 環境変数をセットして nohup "$0" __worker & → exit
  │     No  → osascript フォールバック → exit
  │
  └─ [__worker モード]
        alerter を実行（ブロッキング、最大 120 秒）
        結果に応じてテレポートまたは tmux send-keys
```

#### suppression チェック

```bash
if [ -n "${TMUX_PANE:-}" ]; then
    SESSION_ATTACHED=$(tmux display-message -t "$TMUX_PANE" -p '#{session_attached}' 2>/dev/null || echo 0)
    PANE_ACTIVE=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_active}' 2>/dev/null || echo 0)
    WINDOW_ACTIVE=$(tmux display-message -t "$TMUX_PANE" -p '#{window_active}' 2>/dev/null || echo 0)
    if [[ $SESSION_ATTACHED != 0 && $PANE_ACTIVE == 1 && $WINDOW_ACTIVE == 1 ]]; then
        FRONTMOST=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || echo "")
        [[ "$(echo "$FRONTMOST" | tr '[:upper:]' '[:lower:]')" == "ghostty" ]] && exit 0
    fi
fi
```

チェックと worker 起動の間にユーザーがウィンドウを切り替えても不整合は起きない（最悪、不要な通知が出るだけ）。

#### tmux セッション・ウィンドウ情報の収集

```bash
# tmux 外では空文字になる（後続処理でフォールバック）
SESSION=""
WIN_INDEX=""
SUBTITLE=""
CWD=$(jq -r '.cwd // ""' <<< "$INPUT" 2>/dev/null || echo "")
PROJECT=$(basename "$CWD")

if [ -n "${TMUX_PANE:-}" ]; then
    SESSION=$(tmux display-message -t "$TMUX_PANE" -p '#S' 2>/dev/null || echo "")
    WIN_INDEX=$(tmux display-message -t "$TMUX_PANE" -p '#I' 2>/dev/null || echo "")
    WIN_NAME=$(tmux display-message -t "$TMUX_PANE" -p '#W' 2>/dev/null || echo "")
    TMUX_INFO="${SESSION}"
    [ -n "$WIN_INDEX" ] && [ -n "$WIN_NAME" ] && TMUX_INFO="${SESSION} w${WIN_INDEX} > ${WIN_NAME}"
    [ -n "$TMUX_INFO" ] && [ -n "$PROJECT" ] && SUBTITLE="${TMUX_INFO} · ${PROJECT}" \
        || SUBTITLE="${TMUX_INFO}${PROJECT}"
fi
```

`$INPUT` は `perm-notify.sh` の冒頭で `INPUT=$(cat)` として stdin を読み込んだもの。Notification フックの stdin JSON は `{"type": "permission_prompt", "message": "...", "cwd": "/path/to/project", ...}` の形式。

#### stash ファイル読み込み

```bash
PANE_ID="${TMUX_PANE#%}"
STASH="/tmp/ccnotifs/cmd_${PANE_ID}"
TOOL_DISPLAY=""
if [ -f "$STASH" ]; then
    STASH_TOOL=$(cut -f1 "$STASH")
    STASH_CMD=$(cut -f2- "$STASH")
    [ -n "$STASH_TOOL" ] && TOOL_DISPLAY="${STASH_TOOL}: ${STASH_CMD}"
    rm -f "$STASH"
fi

# BODY は stash 読み込み後に定義（TOOL_DISPLAY が確定してから）
BODY="${TOOL_DISPLAY:-Claude is waiting for your input}"
```

#### 番号付き選択肢の抽出

```bash
SNAPSHOT=$(tmux capture-pane -p -e -J -t "$TMUX_PANE" -S -120 2>/dev/null || echo "")
# ANSI エスケープを除去し "  1. Yes" のような行を抽出
CHOICES=$(printf '%s\n' "$SNAPSHOT" \
    | perl -pe 's/\e\[[0-9;?]*[@-~]//g; s/\r//g' \
    | sed -nE 's/^[[:space:]]*([0-9]+)\.[[:space:]]+(.*)$/\1\t\2/p')
# CHOICES は "1\tYes\n2\tNo" のような改行区切り TAB 区切りテキスト
```

#### alerter worker 起動（メインプロセス側）

```bash
TMUX_SOCK="${TMUX%%,*}"   # "/private/tmp/tmux-xxx/default,..." → "/private/tmp/tmux-xxx/default"

env \
    CCN_PANE="$TMUX_PANE" \
    CCN_SOCK="$TMUX_SOCK" \
    CCN_SESSION="$SESSION" \
    CCN_WIN_INDEX="$WIN_INDEX" \
    CCN_TITLE="Claude Code — Needs Input" \
    CCN_BODY="${TOOL_DISPLAY:-Claude is waiting for your input}" \
    CCN_SUBTITLE="$SUBTITLE" \
    CCN_CHOICES="$CHOICES" \
    nohup "$0" __worker >/dev/null 2>&1 &
```

#### `__worker` ブランチ（デタッチプロセス側）

```bash
if [ "${1:-}" = "__worker" ]; then
    # CCN_CHOICES から --actions 用カンマ区切り文字列を生成
    # CHOICES: "1\tYes\n2\tNo, tell Claude why\n3\tCreate todos first"
    # ラベルにカンマが含まれる場合はセミコロンに置換して衝突を回避
    # セミコロン含みラベルはそのまま（alerter では問題ない）
    ACTIONS=""
    while IFS=$'\t' read -r num label; do
        [ -n "$num" ] || continue
        label=$(printf '%s' "$label" | tr ',' ';' | cut -c1-50)
        label="${num}: ${label}"
        ACTIONS="${ACTIONS:+${ACTIONS},}${label}"
    done <<< "$CCN_CHOICES"
    [ -z "$ACTIONS" ] && ACTIONS="Open"

    ALERTER_ARGS=(
        --title "$CCN_TITLE"
        --message "$CCN_BODY"
        --timeout 120
        --close-label "Dismiss"
        --actions "$ACTIONS"
    )
    [ -n "$CCN_SUBTITLE" ] && ALERTER_ARGS+=(--subtitle "$CCN_SUBTITLE")

    RESULT=$(alerter "${ALERTER_ARGS[@]}" 2>/dev/null || echo "")

    # tmux コマンドは CCN_SOCK 経由で正しいサーバーに接続
    tmux_cmd() { tmux -S "$CCN_SOCK" "$@" 2>/dev/null || true; }

    case "$RESULT" in
        @CONTENTCLICKED|Open)
            # 本体クリック or "Open" ボタン → テレポート
            open -b "com.mitchellh.ghostty"
            tmux_cmd switch-client -t "$CCN_SESSION"
            tmux_cmd select-window -t "${CCN_SESSION}:${CCN_WIN_INDEX}"
            tmux_cmd select-pane -t "$CCN_PANE"
            ;;
        Dismiss|@TIMEOUT|@CLOSED)
            : # 何もしない
            ;;
        *)
            # 番号付きラベル ("1: Yes" など) → 先頭の数字を抽出して送信
            NUM=$(printf '%s' "$RESULT" | sed -nE 's/^([0-9]+):.*/\1/p')
            if [ -n "$NUM" ]; then
                tmux_cmd send-keys -t "$CCN_PANE" -l "$NUM"
                tmux_cmd send-keys -t "$CCN_PANE" Enter
            else
                # 認識できない応答 → テレポートにフォールバック
                open -b "com.mitchellh.ghostty"
                tmux_cmd select-pane -t "$CCN_PANE"
            fi
            ;;
    esac
    exit 0
fi
```

#### osascript フォールバック

alerter 未インストール時、または tmux 外の場合に使用。`$BODY` は stash 読み込み後に定義済み（`BODY="${TOOL_DISPLAY:-Claude is waiting for your input}"`）。

```bash
osascript -e "display notification \"${BODY//\"/\\\"}\" with title \"Claude Code\" sound name \"Ping\""
```

---

### `Brewfile` 追加

```
tap "vjeantet/tap"
brew "vjeantet/tap/alerter"
```

---

### `settings.json` の変更点

**Notification（osascript を `perm-notify.sh` に置き換え）:**

```diff
  "Notification": [
-   {
-     "matcher": "permission_prompt",
-     "hooks": [
-       {"type": "command", "command": "osascript -e 'display notification \"Approve waiting\" with title \"Claude Code\"'"}
-     ]
-   },
+   {
+     "matcher": "permission_prompt",
+     "hooks": [
+       {"type": "command", "command": "~/.claude/hooks/perm-notify.sh"}
+     ]
+   },
    {
      "matcher": "permission_prompt|idle_prompt|elicitation_dialog",
      "hooks": [{"type": "command", "command": "~/.claude/hooks/bark-notify.sh"}]
    }
  ],
```

**PreToolUse（既存エントリに `stash_command.sh` を追記）:**

```diff
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {"type": "command", "command": "node \"/Users/yuyamada/.claude/hooks/gsd-prompt-guard.js\"", "timeout": 5}
      ]
-   }
+   },
+   {
+     "matcher": "",
+     "hooks": [
+       {"type": "command", "command": "~/.claude/hooks/stash_command.sh"}
+     ]
+   }
  ]
```

---

## フォールバック一覧

| 状況 | 動作 |
|---|---|
| alerter インストール済み | アクションボタン付き通知 + テレポート |
| alerter なし | osascript 通知のみ（テレポートなし） |
| tmux 外（`$TMUX_PANE` が空） | `stash_command.sh` は no-op。`perm-notify.sh` は osascript フォールバックのみ |
| スナップショットに選択肢なし | `--actions "Open"` のみ（テレポートのみ） |
| tmux セッションがクリック時に消えていた | `tmux` エラーを無視（`2>/dev/null \|\| true`） |
| suppression 判定からクリックまでにウィンドウ切替 | 最悪、不要な通知が出るだけ（許容） |

## 変更しないもの

- `bark-notify.sh`（スマホへの Bark 通知）
- 他の全フック（PostToolUse, SessionStart, 既存 PreToolUse の `gsd-prompt-guard.js`）
