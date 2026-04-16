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

初回起動後:

1. <http://localhost:3000> にアクセスしてアカウント / 組織 / プロジェクトを作成
2. プロジェクト設定 → API Keys から `pk-lf-...` / `sk-lf-...` を発行
3. `~/.claude/langfuse.env` を編集して keys を埋め、`TRACE_TO_LANGFUSE=true` に切り替え
4. 新しい zsh / Claude Code セッションを起動 (`config/zsh/langfuse.sh` が env を source)

以降、Claude Code の Stop hook (`config/claude/hooks/langfuse_hook.py`) が各ターンを Langfuse に送信する。

### アカウント作成をスキップしたい場合

`~/.claude/langfuse.env` に `LANGFUSE_INIT_*` を設定して compose を再起動すると、初回起動時に org / project / user / API keys が自動シードされ UI 登録が不要になる:

```sh
export LANGFUSE_INIT_ORG_ID="local-org"
export LANGFUSE_INIT_ORG_NAME="local"
export LANGFUSE_INIT_PROJECT_ID="claude-code-project"
export LANGFUSE_INIT_PROJECT_NAME="claude-code"
export LANGFUSE_INIT_PROJECT_PUBLIC_KEY="pk-lf-local-1234"
export LANGFUSE_INIT_PROJECT_SECRET_KEY="sk-lf-local-5678"
export LANGFUSE_INIT_USER_EMAIL="me@local.dev"
export LANGFUSE_INIT_USER_NAME="me"
export LANGFUSE_INIT_USER_PASSWORD="password"
```

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
