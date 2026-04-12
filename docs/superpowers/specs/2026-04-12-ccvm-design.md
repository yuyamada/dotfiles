# ccvm — Lima VM で Claude Code を隔離実行する設計

## 概要

Lima VM 内で Claude Code を auto mode で実行し、VM 内から Docker コンテナも起動できる隔離開発環境を `ccvm` コマンドで管理する。

## 動機

- Claude Code に Docker を含む開発ツールを自由に使わせたい
- auto mode の安全チェック + VM 隔離の二重防御でホストを保護
- 複数プロジェクトを並列で作業できるようにしたい

## ファイル構成

```
config/lima/ccvm.yaml    # Lima VM 定義
bin/ccvm                 # ラッパースクリプト
```

- `bin/ccvm` → `~/.local/bin/ccvm` にシンボリックリンク
- `install.sh` にシンボリックリンク作成を追加

## VM 定義 (`config/lima/ccvm.yaml`)

### スペック

| 項目 | 値 |
|------|-----|
| OS | Ubuntu LTS |
| CPU | 1 コア |
| メモリ | 2GB |
| ディスク | 10GB |

### マウント

| ホスト | VM 内 | モード | 用途 |
|--------|-------|--------|------|
| ワークスペース（引数指定） | `/workspace` | RW | 作業ディレクトリ |
| `~/.claude/` | `/home/<user>.linux/.claude/` | RO | 設定 + 認証 |
| `~/.config/gh/` | `/home/<user>.linux/.config/gh/` | RO | GitHub CLI 認証 |

### プロビジョニング

`provision` スクリプトで以下をインストール:

1. Docker Engine（公式リポジトリ）
2. Claude Code（`npm install -g @anthropic-ai/claude-code`）
3. 基本ツール: git, gh, ripgrep, fd-find, jq, fzf

### ネットワーク

- Lima デフォルト（user-mode networking）
- 制限なし
- auto mode が操作レベルでネットワーク上の危険な操作をブロック

## コマンド (`bin/ccvm`)

### 使い方

```bash
ccvm                          # カレントディレクトリで起動
ccvm ~/workspace/project      # 指定ディレクトリで起動
ccvm stop <name>              # 指定 VM を停止
ccvm stop --all               # 全 ccvm VM を停止
ccvm delete <name>            # 指定 VM を削除
ccvm delete --all             # 全 ccvm VM を削除
ccvm list                     # ccvm VM の一覧
```

### VM 命名規則

`ccvm-<ディレクトリ名>`

```
ccvm ~/workspace/my-project    → ccvm-my-project
ccvm ~/workspace/dotfiles      → ccvm-dotfiles
ccvm                           → ccvm-<カレントディレクトリ名>
```

### 起動フロー

```
ccvm <path>
  ↓
1. ディレクトリ名から VM 名を決定 (ccvm-<dirname>)
2. VM が未作成 → limactl create + limactl start
   VM が停止中 → limactl start
   VM が起動済み → そのまま
3. limactl shell で VM に接続
4. VM 内で claude --permission-mode auto を実行
5. Claude Code 終了後、VM は放置（リソース軽量のため）
```

### limactl との対応

| ccvm | limactl |
|------|---------|
| `ccvm <path>` | `create` + `start` + `shell` + `claude` |
| `ccvm stop <name>` | `limactl stop ccvm-<name>` |
| `ccvm stop --all` | 全 `ccvm-*` に `limactl stop` |
| `ccvm delete <name>` | `limactl delete ccvm-<name>` |
| `ccvm delete --all` | 全 `ccvm-*` に `limactl delete` |
| `ccvm list` | `limactl list` を `ccvm-*` でフィルタ |

## tmux での使い方

```
ホストの tmux session
├── pane 0: nvim（ホスト側、RW マウントで VM と同期）
├── pane 1: ccvm ~/workspace/project
└── pane 2: limactl shell ccvm-project（必要に応じて）
```

- tmux はホスト側で動作
- nvim もホスト側で RW マウント経由でファイル編集
- VM 内には tmux 不要

## セキュリティモデル

二重防御:

- **VM 隔離**: ホストのファイルシステム・プロセスを保護。RO マウントで設定・認証の改変を防止
- **auto mode**: Sonnet 4.6 分類モデルが操作ごとに安全性を判定。危険な操作（force push、本番デプロイ、大量削除、データ流出等）をブロック

## 前提条件

- Lima がホストにインストール済み（`brew install lima`）
- Claude Code の auto mode が利用可能（Team/Enterprise/API プラン + Sonnet 4.6+）
- ホストに `~/.claude/` と `~/.config/gh/` の認証情報がセットアップ済み
