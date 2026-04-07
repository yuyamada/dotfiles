# Clipboard Plugin Design

## Overview

macOS のクリップボード操作（読み取り・書き込み・履歴）を MCP サーバーとして提供する Claude Code プラグイン。プラグイン開発とマーケットプレイス公開の学習を兼ねる。

## Goals

1. MCP サーバー付きプラグインの構造と仕組みを理解する
2. カスタムマーケットプレイスによる配布の仕組みを理解する
3. 実用的なクリップボード操作ツールを得る

## Repository

- **リポジトリ**: `yuyamada/claude-plugins`（private）
- **用途**: カスタムマーケットプレイス兼プラグイン格納

## Directory Structure

```
claude-plugins/
├── plugins/
│   └── clipboard/
│       └── 1.0.0/
│           ├── .claude-plugin/
│           │   └── plugin.json
│           ├── src/
│           │   └── index.ts
│           ├── dist/
│           │   └── index.js          ← ビルド成果物（コミット対象）
│           ├── skills/
│           │   └── clipboard/
│           │       └── SKILL.md
│           ├── package.json
│           └── tsconfig.json
├── README.md
└── LICENSE
```

## MCP Server

### Transport

- `stdio`（標準入出力）で Claude Code と通信
- Claude Code がプロセスの起動・管理を担当

### Tools

| Tool | Description | Arguments | Returns |
|------|-------------|-----------|---------|
| `clipboard_read` | クリップボードの現在の内容を取得 | なし | `string` |
| `clipboard_write` | クリップボードにテキストを書き込む | `text: string` | 成功メッセージ |
| `clipboard_history` | セッション中の書き込み履歴を表示 | `limit?: number` (default: 10) | 履歴配列 |

### Implementation

- `pbpaste` / `pbcopy` を `child_process.execSync` で呼び出し
- `clipboard_history` はメモリ内配列で管理（MCP サーバープロセス終了で消える）
- `@modelcontextprotocol/sdk` を使用

## Plugin Configuration

### plugin.json

```json
{
  "name": "clipboard",
  "version": "1.0.0",
  "description": "macOS clipboard read/write/history via MCP",
  "author": {
    "name": "Yu Yamada",
    "url": "https://github.com/yuyamada"
  },
  "repository": "https://github.com/yuyamada/claude-plugins",
  "license": "MIT",
  "mcpServers": {
    "clipboard": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/dist/index.js"]
    }
  }
}
```

## Skill

### SKILL.md

- スキル名: `clipboard`
- Claude がクリップボードツールを自然に使えるようガイド
- 利用例:
  - 「クリップボードの内容を確認して」→ `clipboard_read`
  - 「この結果をクリップボードにコピーして」→ `clipboard_write`
  - 「さっきコピーしたもの見せて」→ `clipboard_history`

## Marketplace Registration

利用者側の `settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "yuyamada-plugins": {
      "source": {
        "source": "git",
        "url": "git@github.com:yuyamada/claude-plugins"
      }
    }
  },
  "enabledPlugins": {
    "clipboard@yuyamada-plugins": true
  }
}
```

- `"source": "git"` + SSH URL で private リポに対応
- `enabledPlugins` で有効化後、`/reload-plugins` で反映

## Build

- TypeScript → JavaScript にコンパイルして `dist/` に出力
- `dist/` はコミット対象（Claude Code はインストール時にビルドを実行しないため）

## Version Update

新バージョンは `plugins/clipboard/<new-version>/` に追加。旧バージョンも残置可能。
