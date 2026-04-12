# Claude Code Devcontainer Design

## Summary

Docker コンテナ内で Claude Code を実行するための汎用的な構成。
sandbox 環境よりもエージェントに権限を移譲しつつ、ネットワーク層のファイアウォールで安全性を担保する。

## Motivation

- ローカルの sandbox 設定ではファイルシステム書き込み制限等が厳しく、エージェントの自律性が制限される
- コンテナ隔離 + ファイアウォール + deny リストの多層防御により、`--dangerously-skip-permissions` を安全に使える環境を提供する
- ホストの Claude Code 設定（settings.json, rules, skills, hooks）をそのまま再利用する

## File Structure

```
config/claude/devcontainer/
├── Dockerfile      # 公式イメージ継承 + 追加ツール
└── compose.yml     # マウント・認証・起動設定
```

## Dockerfile

- ベースイメージ: `ghcr.io/anthropics/claude-code:latest`
  - Node.js 20, Claude Code CLI, git, gh CLI, zsh, fzf, jq, iptables, ipset 等がプリインストール
  - `/usr/local/bin/init-firewall.sh` 内蔵（deny-by-default ネットワークポリシー）
- 追加パッケージ: ripgrep, fd-find（Claude Code の検索で有用）

## compose.yml

### Volumes

| マウント | コンテナパス | モード | 目的 |
|---|---|---|---|
| `../../settings.json` | `/home/node/.claude/settings.json` | ro | パーミッション設定・プラグイン |
| `../../rules/` | `/home/node/.claude/rules/` | ro | カスタムルール |
| `../../skills/` | `/home/node/.claude/skills/` | ro | カスタムスキル |
| `../../hooks/` | `/home/node/.claude/hooks/` | ro | フック |
| `../../CLAUDE.md` | `/home/node/.claude/CLAUDE.md` | ro | プロジェクト指示 |
| `~/workspace` | `/workspace` | rw | 作業ディレクトリ |

すべての設定は読み取り専用（`:ro`）でマウントし、コンテナから変更されることを防ぐ。

### Authentication

| 環境変数 | 用途 | 取得方法 |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code 認証（サブスク） | `claude setup-token`（1年有効） |
| `GH_TOKEN` | GitHub CLI 認証 | `gh auth token`（ホストセッションから取得） |

環境変数はホスト側でセットし、compose.yml で参照するだけ（値を直接書かない）。

### Security

- `cap_add: NET_ADMIN, NET_RAW` — ファイアウォール初期化に必要
- `entrypoint` でコンテナ起動時に `init-firewall.sh` を自動実行
- ファイアウォール: deny-by-default、ホワイトリスト方式
  - 許可: api.anthropic.com, github.com, api.github.com, registry.npmjs.org, localhost, DNS
  - 拒否: それ以外すべて
- `settings.json` の `permissions.deny` がコンテナ内でも有効（`--dangerously-skip-permissions` でも突破されない）

### Runtime

- ユーザー: `node`（non-root）
- 作業ディレクトリ: `/workspace`
- `stdin_open: true`, `tty: true` — インタラクティブ操作対応

## Usage

```bash
# 1. トークン準備（初回のみ）
claude setup-token
export CLAUDE_CODE_OAUTH_TOKEN="生成されたトークン"
export GH_TOKEN="$(gh auth token)"

# 2. 起動
cd ~/workspace/dotfiles/config/claude/devcontainer
docker compose up -d

# 3. Claude Code 実行
docker compose exec claude claude --dangerously-skip-permissions

# 4. 停止
docker compose down
```

## Design Decisions

| 判断 | 選択 | 理由 |
|---|---|---|
| ベースイメージ | 公式 `ghcr.io/anthropics/claude-code:latest` を継承 | ファイアウォール込み、メンテコスト最小 |
| 設定ファイル形式 | `compose.yml`（devcontainer.json なし） | VS Code 非依存、`docker compose` で完結 |
| 認証方式 | `CLAUDE_CODE_OAUTH_TOKEN` | サブスク課金、1年有効、ヘッドレス対応 |
| 設定の共有 | ホストと同じ settings.json を `:ro` マウント | 設定分岐は必要になってから |
| シェル環境 | 公式イメージの zsh をそのまま使用 | sheldon/starship は不要（Claude Code 実行が主目的） |
| ファイアウォール | 公式 `init-firewall.sh` をそのまま使用 | 実績のある deny-by-default ポリシー |

## Future Considerations

- コンテナ用の `settings.json` が必要になったら分離する
- macOS 固有のフック（bark-notify 等）がエラーになる場合、コンテナ判定で分岐を入れる
- `devcontainer.json` は VS Code / Neovim プラグインで使いたくなったら追加可能
- MCP サーバー（aws-documentation 等）のコンテナ内動作確認が必要
