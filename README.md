# dotfiles

Personal macOS dotfiles.

## Setup

```sh
git clone https://github.com/yuyamada/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
brew bundle
./install.sh
```

`install.sh` creates symlinks from `config/` to the appropriate locations. See the script for details.

## Langfuse (Claude Code local observability)

Claude Code の会話ログ (プロンプト / tool use 履歴) をローカルの [Langfuse](https://langfuse.com/) で追跡する。機密情報を含みうるため、クラウドには送信しない前提の構成。

### 前提

- Rancher Desktop (dockerd モード) が起動していること
- `docker` / `docker compose` コマンドが使えること

### 初回セットアップ

```sh
langfuse-setup
```

以下を行う:

1. Langfuse 公式リポジトリを `~/.local/share/langfuse` にクローン
2. `config/langfuse/env.template` を `~/.claude/langfuse.env` にコピー
3. `docker compose up -d` で起動 (`restart: always` により dockerd 起動時に自動復帰)

初回起動後:

1. <http://localhost:3000> にアクセスしてアカウント / 組織 / プロジェクトを作成
2. プロジェクト設定 → API Keys から `pk-lf-...` / `sk-lf-...` を発行
3. `~/.claude/langfuse.env` を編集して keys を埋め、`TRACE_TO_LANGFUSE=true` に切り替え
4. 新しい zsh / Claude Code セッションを起動 (`config/zsh/langfuse.sh` が env を source)

以降、Claude Code の Stop hook (`config/claude/hooks/langfuse-trace.py`) が各ターンを Langfuse に送信する。

### Mac 再起動後の自動復帰

- Rancher Desktop の Preferences → General → "Automatically start at login" を有効化
- docker compose の各サービスは `restart: always` のため、dockerd が起動すれば自動で立ち上がる
- 手動再起動: `cd ~/.local/share/langfuse && docker compose up -d`

### 停止

```sh
cd ~/.local/share/langfuse && docker compose down
```

### 設計メモ

- LiteLLM proxy などのプロキシ経由ではなく Claude Code の Stop hook 方式を採用 (サプライチェーンリスクを避けるため)
- hook は stdlib のみを使い、Langfuse の [public ingestion API](https://api.reference.langfuse.com/) に直接 POST する (SDK 依存なし)
- state は `~/.claude/langfuse-state/<session_id>.json` に保存し、新規ターンのみを送信する
- `TRACE_TO_LANGFUSE` が `true` でないときは hook は即座に no-op で終了する
