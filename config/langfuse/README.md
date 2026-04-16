# Langfuse (Claude Code local observability)

Claude Code の会話ログ (プロンプト / tool use 履歴) をローカルの [Langfuse](https://langfuse.com/) で追跡する。機密情報を含みうるため、クラウドには送信しない前提の構成。公式の [Trace Claude Code with Langfuse](https://langfuse.com/integrations/other/claude-code) に沿った Stop hook 方式。

## 前提

- Rancher Desktop (dockerd モード) が起動していること
- `docker` / `docker compose` / `python3` が使えること

## 初回セットアップ

```sh
langfuse-setup
```

以下を行う:

1. Langfuse 公式リポジトリを `~/.local/share/langfuse` にクローン
2. `~/.claude/langfuse-venv` に hook 用 venv を作り `langfuse` SDK を導入
3. `config/langfuse/env.template` を `~/.claude/langfuse.env` にコピー
4. `docker compose up -d` で起動 (`restart: always` により dockerd 起動時に自動復帰)

`env.template` には `LANGFUSE_INIT_*` を含むダミーのローカル資格情報が埋め込まれているため、追加の設定なしでそのまま使える:

- API キー: `pk-lf-local-1234` / `sk-lf-local-5678`
- UI ログイン: `me@local.dev` / `password`
- 初回起動時に org / project / user / API keys が自動シードされ UI 登録は不要

新しい zsh / Claude Code セッションを起動すれば `config/zsh/langfuse.sh` が env を source し、Claude Code の Stop hook (`config/claude/hooks/langfuse_hook.py`) が各ターンを Langfuse に送信する。

資格情報を変えたい場合は `~/.claude/langfuse.env` を直接編集する (dotfiles には含まれないマシン固有ファイル)。

## Mac 再起動後の自動復帰

- Rancher Desktop の Preferences → General → "Automatically start at login" を有効化
- docker compose の各サービスは `restart: always` のため、dockerd が起動すれば自動で立ち上がる
- 手動再起動: `cd ~/.local/share/langfuse && docker compose up -d`

## 停止

```sh
cd ~/.local/share/langfuse && docker compose down
```

## 設計メモ

- hook スクリプト (`config/claude/hooks/langfuse_hook.py`) は [公式ドキュメント](https://langfuse.com/integrations/other/claude-code) の実装をそのまま採用
- `from langfuse import Langfuse, propagate_attributes` を直接 import するため、専用 venv (`~/.claude/langfuse-venv`) を用意し SDK を導入
- settings.json の Stop hook は `bash -c 'source ~/.claude/langfuse.env; exec ~/.claude/langfuse-venv/bin/python ...'` で env を毎回 source する (GUI 起動時も確実に env が渡る)
- state は `~/.claude/state/langfuse_state.json` (offset + buffer + turn_count) に保存し、transcript の新規バイトだけを再読込
- `fcntl.flock` でロック、SDK import 失敗時は `sys.exit(0)` で fail-open
- `TRACE_TO_LANGFUSE` が `true` でないときは hook は即座に no-op で終了する
- 環境変数は公式 hook の仕様に合わせ `CC_LANGFUSE_*` / `LANGFUSE_*` の両方を受け付ける (`BASE_URL` / `PUBLIC_KEY` / `SECRET_KEY`)
- ターン毎に 3 つのスコアを Langfuse に POST: `tool_count` / `tool_error_count` / `tool_error_rate` (最後はツール使用ありターンのみ)
- `TELEMETRY_ENABLED=false` を設定すると Langfuse 本体から Langfuse.com への使用統計送信を無効化できる
