# Notification Pane Focus Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Code の承認待ち通知をクリックすると Ghostty + tmux ペーンにテレポートし、通知から直接 Yes/No 承認もできるようにする。

**Architecture:** `alerter` を使って macOS 通知にアクションボタンを追加する。Claude の PreToolUse フックでツール名・コマンドを一時ファイルに stash し、Notification フックで stash を読んで通知を送る。alerter の結果に応じて tmux send-keys（承認）または open + tmux select-pane（テレポート）を実行する。

**Tech Stack:** bash, alerter (vjeantet/tap), jq, tmux, osascript, Claude Code hooks

---

## File Map

| ファイル | 操作 | 役割 |
|---|---|---|
| `config/claude/hooks/stash_command.sh` | **新規作成** | PreToolUse: ツール名・コマンドを `/tmp/ccnotifs/cmd_<PANE_ID>` に保存 |
| `config/claude/hooks/perm-notify.sh` | **新規作成** | Notification: stash を読んで alerter 通知、テレポート・承認を処理 |
| `Brewfile` | **修正** | `alerter` を追加 |
| `config/claude/settings.json` | **修正** | osascript 通知を `perm-notify.sh` に置き換え、PreToolUse に `stash_command.sh` を追加 |

---

### Task 1: alerter のインストール

**Files:**
- Modify: `Brewfile`

- [ ] **Step 1: Brewfile に alerter を追加**

```
# Brewfile の git-delta 行の後に追加
tap "vjeantet/tap"
brew "vjeantet/tap/alerter"
```

`Brewfile` を開き、`brew "vjeantet/tap/alerter"` 行が存在しない場合に追記する。

- [ ] **Step 2: alerter をインストール**

```bash
brew install vjeantet/tap/alerter
```

- [ ] **Step 3: インストール確認**

```bash
which alerter
alerter --help 2>&1 | head -5
```

Expected: `/opt/homebrew/bin/alerter` のようなパスが出力される。

- [ ] **Step 4: コミット**

```bash
git add Brewfile
git commit -m "chore(deps): add alerter for interactive macOS notifications"
```

---

### Task 2: stash_command.sh の作成

**Files:**
- Create: `config/claude/hooks/stash_command.sh`

- [ ] **Step 1: スクリプトを作成**

`config/claude/hooks/stash_command.sh` を以下の内容で作成する:

```bash
#!/bin/bash
# PreToolUse フック: ツール名・コマンドを一時ファイルに保存
# perm-notify.sh が通知本文に使用する

set -euo pipefail

# tmux 外では何もしない
[ -n "${TMUX_PANE:-}" ] || exit 0

INPUT=$(cat)
PANE_ID="${TMUX_PANE#%}"           # "%3" → "3"
TOOL=$(jq -r '.tool_name // ""' <<< "$INPUT" 2>/dev/null || echo "")
CMD=$(jq -r '(.tool_input.command // .tool_input.path // "") | .[0:80]' \
    <<< "$INPUT" 2>/dev/null || echo "")

mkdir -p /tmp/ccnotifs
printf '%s\t%s\n' "$TOOL" "$CMD" > "/tmp/ccnotifs/cmd_${PANE_ID}"
```

- [ ] **Step 2: 実行権限を付与**

```bash
chmod +x config/claude/hooks/stash_command.sh
```

- [ ] **Step 3: 動作確認（tmux 内で実行すること）**

```bash
# シミュレート: Bash ツールの PreToolUse 入力を渡す
echo '{"tool_name":"Bash","tool_input":{"command":"git status"},"cwd":"/tmp"}' \
    | TMUX_PANE="%3" bash config/claude/hooks/stash_command.sh

# 出力ファイルを確認
cat /tmp/ccnotifs/cmd_3
```

Expected: `Bash	git status`

- [ ] **Step 4: tmux 外での no-op を確認**

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"test"}}' \
    | TMUX_PANE="" bash config/claude/hooks/stash_command.sh
echo "exit code: $?"
# /tmp/ccnotifs/cmd_ ファイルが作られていないこと
ls /tmp/ccnotifs/ 2>/dev/null || echo "no files (expected)"
```

Expected: exit code 0、ファイル未作成。

- [ ] **Step 5: コミット**

```bash
git add config/claude/hooks/stash_command.sh
git commit -m "feat(hooks): add stash_command.sh to cache tool info for notifications"
```

---

### Task 3: perm-notify.sh の作成

**Files:**
- Create: `config/claude/hooks/perm-notify.sh`

- [ ] **Step 1: スクリプトを作成**

`config/claude/hooks/perm-notify.sh` を以下の内容で作成する:

```bash
#!/bin/bash
# Notification フック: permission_prompt 時に alerter 通知を送る
# クリックで Ghostty + tmux ペーンにテレポート、番号選択で承認/拒否

set -euo pipefail

# ──────────────────────────────────────────────────
# __worker モード: alerter 実行とアクション処理（デタッチプロセス）
# ──────────────────────────────────────────────────
if [ "${1:-}" = "__worker" ]; then
    # CCN_CHOICES (改行区切り "num\tlabel") → alerter --actions カンマ区切り文字列
    ACTIONS=""
    while IFS=$'\t' read -r num label; do
        [ -n "$num" ] || continue
        label=$(printf '%s' "$label" | tr ',' ';' | cut -c1-50)
        label="${num}: ${label}"
        ACTIONS="${ACTIONS:+${ACTIONS},}${label}"
    done <<< "${CCN_CHOICES:-}"
    [ -z "$ACTIONS" ] && ACTIONS="Open"

    ALERTER_ARGS=(
        --title "${CCN_TITLE:-Claude Code}"
        --message "${CCN_BODY:-Claude is waiting for your input}"
        --timeout 120
        --close-label "Dismiss"
        --actions "$ACTIONS"
    )
    [ -n "${CCN_SUBTITLE:-}" ] && ALERTER_ARGS+=(--subtitle "$CCN_SUBTITLE")

    RESULT=$(alerter "${ALERTER_ARGS[@]}" 2>/dev/null || echo "")

    # CCN_SOCK 経由で正しい tmux サーバーに接続
    tmux_cmd() { tmux -S "${CCN_SOCK}" "$@" 2>/dev/null || true; }

    case "$RESULT" in
        "@CONTENTCLICKED"|Open)
            # 本体クリック or "Open" ボタン → テレポート
            open -b "com.mitchellh.ghostty"
            tmux_cmd switch-client -t "${CCN_SESSION}"
            tmux_cmd select-window -t "${CCN_SESSION}:${CCN_WIN_INDEX}"
            tmux_cmd select-pane -t "${CCN_PANE}"
            ;;
        Dismiss|"@TIMEOUT"|"@CLOSED")
            : # 何もしない
            ;;
        *)
            # 番号付きラベル ("1: Yes" など) → 先頭の数字を抽出して tmux に送信
            NUM=$(printf '%s' "$RESULT" | sed -nE 's/^([0-9]+):.*/\1/p')
            if [ -n "$NUM" ]; then
                tmux_cmd send-keys -t "${CCN_PANE}" -l "$NUM"
                tmux_cmd send-keys -t "${CCN_PANE}" Enter
            else
                # 認識できない応答 → テレポートにフォールバック
                open -b "com.mitchellh.ghostty"
                tmux_cmd select-pane -t "${CCN_PANE}"
            fi
            ;;
    esac
    exit 0
fi

# ──────────────────────────────────────────────────
# メインフック処理
# ──────────────────────────────────────────────────
INPUT=$(cat)

# tmux 外: osascript フォールバックのみ
if [ -z "${TMUX_PANE:-}" ]; then
    CWD=$(jq -r '.cwd // ""' <<< "$INPUT" 2>/dev/null || echo "")
    BODY="Claude is waiting for your input"
    osascript -e "display notification \"${BODY}\" with title \"Claude Code\" sound name \"Ping\""
    exit 0
fi

# suppression チェック: 既にそのペーンを見ていれば通知不要
SESSION_ATTACHED=$(tmux display-message -t "$TMUX_PANE" -p '#{session_attached}' 2>/dev/null || echo 0)
PANE_ACTIVE=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_active}' 2>/dev/null || echo 0)
WINDOW_ACTIVE=$(tmux display-message -t "$TMUX_PANE" -p '#{window_active}' 2>/dev/null || echo 0)
if [[ $SESSION_ATTACHED != 0 && $PANE_ACTIVE == 1 && $WINDOW_ACTIVE == 1 ]]; then
    FRONTMOST=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || echo "")
    [[ "$(echo "$FRONTMOST" | tr '[:upper:]' '[:lower:]')" == "ghostty" ]] && exit 0
fi

# tmux セッション・ウィンドウ情報の収集
SESSION=$(tmux display-message -t "$TMUX_PANE" -p '#S' 2>/dev/null || echo "")
WIN_INDEX=$(tmux display-message -t "$TMUX_PANE" -p '#I' 2>/dev/null || echo "")
WIN_NAME=$(tmux display-message -t "$TMUX_PANE" -p '#W' 2>/dev/null || echo "")
CWD=$(jq -r '.cwd // ""' <<< "$INPUT" 2>/dev/null || echo "")
PROJECT=$(basename "$CWD")
TMUX_INFO="${SESSION}"
[ -n "$WIN_INDEX" ] && [ -n "$WIN_NAME" ] && TMUX_INFO="${SESSION} w${WIN_INDEX} > ${WIN_NAME}"
if [ -n "$TMUX_INFO" ] && [ -n "$PROJECT" ]; then
    SUBTITLE="${TMUX_INFO} · ${PROJECT}"
elif [ -n "$TMUX_INFO" ]; then
    SUBTITLE="$TMUX_INFO"
else
    SUBTITLE="$PROJECT"
fi

# stash ファイルからツール名・コマンドを読み込み（読み込み後に削除）
PANE_ID="${TMUX_PANE#%}"
STASH="/tmp/ccnotifs/cmd_${PANE_ID}"
TOOL_DISPLAY=""
if [ -f "$STASH" ]; then
    STASH_TOOL=$(cut -f1 "$STASH")
    STASH_CMD=$(cut -f2- "$STASH")
    [ -n "$STASH_TOOL" ] && TOOL_DISPLAY="${STASH_TOOL}: ${STASH_CMD}"
    rm -f "$STASH"
fi

# BODY は TOOL_DISPLAY 確定後に定義
BODY="${TOOL_DISPLAY:-Claude is waiting for your input}"

# tmux ペーンのスナップショットから番号付き選択肢を抽出
SNAPSHOT=$(tmux capture-pane -p -e -J -t "$TMUX_PANE" -S -120 2>/dev/null || echo "")
CHOICES=$(printf '%s\n' "$SNAPSHOT" \
    | perl -pe 's/\e\[[0-9;?]*[@-~]//g; s/\r//g' \
    | sed -nE 's/^[[:space:]]*([0-9]+)\.[[:space:]]+(.*)$/\1\t\2/p')

# alerter が使えるか確認
ALERTER_BIN=$(command -v alerter 2>/dev/null || echo "")
if [ -z "$ALERTER_BIN" ]; then
    # フォールバック: osascript（テレポートなし）
    osascript -e "display notification \"${BODY//\"/\\\"}\" with title \"Claude Code\" sound name \"Ping\""
    exit 0
fi

# alerter worker をデタッチ起動（環境変数でコンテキストを渡す）
TMUX_SOCK="${TMUX%%,*}"
env \
    CCN_PANE="$TMUX_PANE" \
    CCN_SOCK="$TMUX_SOCK" \
    CCN_SESSION="$SESSION" \
    CCN_WIN_INDEX="$WIN_INDEX" \
    CCN_TITLE="Claude Code — Needs Input" \
    CCN_BODY="$BODY" \
    CCN_SUBTITLE="$SUBTITLE" \
    CCN_CHOICES="$CHOICES" \
    nohup "$0" __worker >/dev/null 2>&1 &
exit 0
```

- [ ] **Step 2: 実行権限を付与**

```bash
chmod +x config/claude/hooks/perm-notify.sh
```

- [ ] **Step 3: osascript フォールバック動作を確認（alerter を一時的に隠してテスト）**

```bash
# alerter を PATH から外してフォールバックをテスト
echo '{"cwd":"/Users/yuyamada/workspace/dotfiles"}' \
    | TMUX_PANE="%3" PATH="/usr/bin:/bin" bash config/claude/hooks/perm-notify.sh
```

Expected: macOS の右上に通知が表示される（Script Editor でなく osascript 経由）。

- [ ] **Step 4: stash → 通知本文の連携を確認（tmux 内で実行すること）**

```bash
# stash ファイルを手動で作成
mkdir -p /tmp/ccnotifs
printf 'Bash\tgit commit -m "test"\n' > "/tmp/ccnotifs/cmd_${TMUX_PANE#%}"

# フックをシミュレート
echo '{"cwd":"/Users/yuyamada/workspace/dotfiles"}' \
    | bash config/claude/hooks/perm-notify.sh
```

Expected: 通知本文に `Bash: git commit -m "test"` が表示される。

- [ ] **Step 5: コミット**

```bash
git add config/claude/hooks/perm-notify.sh
git commit -m "feat(hooks): add perm-notify.sh with alerter teleport and approval"
```

---

### Task 4: symlink を張る

**Files:**
- Run: `install.sh`

- [ ] **Step 1: install.sh を実行して symlink を作成**

```bash
bash install.sh
```

既存ファイルを上書きするか確認を求められた場合は `n` を選択（既存 hook は変更しない）。

- [ ] **Step 2: symlink を確認**

```bash
ls -la ~/.claude/hooks/perm-notify.sh ~/.claude/hooks/stash_command.sh
```

Expected: 両ファイルが `config/claude/hooks/` へのシンボリックリンクとして表示される。

---

### Task 5: settings.json の更新

**Files:**
- Modify: `config/claude/settings.json`

- [ ] **Step 1: Notification セクションを更新（osascript → perm-notify.sh）**

`config/claude/settings.json` の以下の箇所を変更する:

変更前:
```json
{
  "matcher": "permission_prompt",
  "hooks": [
    {
      "type": "command",
      "command": "osascript -e 'display notification \"Approve waiting\" with title \"Claude Code\"'"
    }
  ]
}
```

変更後:
```json
{
  "matcher": "permission_prompt",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/hooks/perm-notify.sh"
    }
  ]
}
```

- [ ] **Step 2: PreToolUse セクションに stash_command.sh を追加**

既存の PreToolUse ブロック末尾（`gsd-prompt-guard.js` エントリの閉じ括弧の後）に追記:

```json
,
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/hooks/stash_command.sh"
    }
  ]
}
```

- [ ] **Step 3: JSON の構文を確認**

```bash
jq . config/claude/settings.json > /dev/null && echo "JSON valid"
```

Expected: `JSON valid`

- [ ] **Step 4: コミット**

```bash
git add config/claude/settings.json
git commit -m "feat(claude): replace osascript notification with alerter teleport hook"
```

---

### Task 6: エンドツーエンドの動作確認

このタスクは Claude Code を再起動してから tmux 内で実施する。

- [ ] **Step 1: Claude Code を再起動**（hooks の再読み込みのため）

- [ ] **Step 2: 通知が届くか確認**

Claude Code で権限が必要なコマンド（例: ファイル書き込み）を実行し、承認待ち状態にする。
右上に "Claude Code — Needs Input" の通知が届くことを確認する。

- [ ] **Step 3: テレポート確認**

通知の本体（または "Open" ボタン）をクリックし、以下を確認:
- Ghostty がフォーカスされる
- 正しい tmux ペーンがアクティブになる

- [ ] **Step 4: 承認ボタン確認**

通知に番号付き選択肢ボタンが表示されている場合、数字ボタンをクリックして承認が通ることを確認する。

- [ ] **Step 5: suppression 確認**

Ghostty をフロントにした状態（既にそのペーンを見ている状態）でトリガーし、通知が来ないことを確認する。

- [ ] **Step 6: Bark 通知が引き続き届くことを確認**

スマホに Bark 通知が届いていることを確認（既存の `bark-notify.sh` が維持されているため）。
