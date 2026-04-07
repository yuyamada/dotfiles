# Clipboard Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** macOS クリップボード操作（読み取り・書き込み・履歴）を MCP サーバーとして提供する Claude Code プラグインを作成し、カスタムマーケットプレイスとして配布する。

**Architecture:** TypeScript で MCP サーバーを実装し、`@modelcontextprotocol/sdk` の `McpServer` + `StdioServerTransport` で Claude Code と stdio 通信する。`pbcopy`/`pbpaste` コマンドを `child_process` で呼び出してクリップボードを操作する。プラグインは `yuyamada/claude-plugins` private リポジトリにマーケットプレイス形式で格納する。

**Tech Stack:** TypeScript, `@modelcontextprotocol/sdk`, Node.js `child_process`, zod

---

## File Structure

```
claude-plugins/                          # GitHub リポジトリルート
├── plugins/
│   └── clipboard/
│       └── 1.0.0/
│           ├── .claude-plugin/
│           │   └── plugin.json          # プラグインメタデータ + MCP サーバー定義
│           ├── src/
│           │   └── index.ts             # MCP サーバー実装（ツール定義・ハンドラー）
│           ├── dist/
│           │   └── index.js             # ビルド成果物（コミット対象）
│           ├── skills/
│           │   └── clipboard/
│           │       └── SKILL.md         # ツール使い方ガイド
│           ├── package.json             # 依存関係
│           └── tsconfig.json            # TypeScript 設定
├── README.md
└── LICENSE
```

---

### Task 1: GitHub リポジトリとプロジェクト骨格の作成

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `plugins/clipboard/1.0.0/package.json`
- Create: `plugins/clipboard/1.0.0/tsconfig.json`

- [ ] **Step 1: GitHub に private リポジトリを作成**

Run: `gh repo create yuyamada/claude-plugins --private --description "Custom Claude Code plugins marketplace" --clone`
Expected: リポジトリが作成されローカルにクローンされる

- [ ] **Step 2: ディレクトリ構造を作成**

Run: `mkdir -p plugins/clipboard/1.0.0/{.claude-plugin,src,skills/clipboard}`

- [ ] **Step 3: package.json を作成**

`plugins/clipboard/1.0.0/package.json`:
```json
{
  "name": "claude-plugin-clipboard",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "watch": "tsc --watch"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.27.1",
    "zod": "^3.24.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "typescript": "^5.7.0"
  },
  "engines": {
    "node": ">=20"
  }
}
```

- [ ] **Step 4: tsconfig.json を作成**

`plugins/clipboard/1.0.0/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true
  },
  "include": ["src"]
}
```

- [ ] **Step 5: README.md を作成**

`README.md`:
```markdown
# claude-plugins

Custom Claude Code plugins marketplace.

## Plugins

- **clipboard** — macOS clipboard read/write/history via MCP

## Usage

Add to your `~/.claude/settings.json`:

\`\`\`json
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
\`\`\`
```

- [ ] **Step 6: LICENSE を作成**

`LICENSE`: MIT ライセンス（著作者: Yu Yamada, 年: 2026）

- [ ] **Step 7: 依存関係をインストール**

Run: `cd plugins/clipboard/1.0.0 && npm install`
Expected: `node_modules/` が作成され `@modelcontextprotocol/sdk` と `zod` がインストールされる

- [ ] **Step 8: .gitignore を作成**

`plugins/clipboard/1.0.0/.gitignore`:
```
node_modules/
```

Note: `dist/` はコミット対象なので除外しない。

- [ ] **Step 9: コミット**

```bash
git add -A
git commit -m "chore: scaffold clipboard plugin project"
```

---

### Task 2: MCP サーバーの実装

**Files:**
- Create: `plugins/clipboard/1.0.0/src/index.ts`

- [ ] **Step 1: MCP サーバーの基本構造を実装**

`plugins/clipboard/1.0.0/src/index.ts`:
```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { execSync } from "node:child_process";
import { z } from "zod";

const history: Array<{ text: string; timestamp: string }> = [];

const server = new McpServer({
  name: "clipboard",
  version: "1.0.0",
});

server.tool("clipboard_read", "Read current clipboard contents (macOS pbpaste)", {}, async () => {
  const text = execSync("pbpaste", { encoding: "utf-8" });
  return {
    content: [{ type: "text", text: text || "(clipboard is empty)" }],
  };
});

server.tool(
  "clipboard_write",
  "Write text to clipboard (macOS pbcopy)",
  { text: z.string().describe("Text to write to clipboard") },
  async ({ text }) => {
    execSync("pbcopy", { input: text, encoding: "utf-8" });
    history.push({ text, timestamp: new Date().toISOString() });
    return {
      content: [
        {
          type: "text",
          text: `Wrote ${text.length} characters to clipboard.`,
        },
      ],
    };
  },
);

server.tool(
  "clipboard_history",
  "Show clipboard write history for this session",
  {
    limit: z
      .number()
      .optional()
      .default(10)
      .describe("Maximum number of history entries to return"),
  },
  async ({ limit }) => {
    const entries = history.slice(-limit).reverse();
    if (entries.length === 0) {
      return {
        content: [{ type: "text", text: "No clipboard history yet." }],
      };
    }
    const formatted = entries
      .map(
        (entry, i) =>
          `${i + 1}. [${entry.timestamp}] ${entry.text.length > 100 ? entry.text.slice(0, 100) + "..." : entry.text}`,
      )
      .join("\n");
    return {
      content: [{ type: "text", text: formatted }],
    };
  },
);

const transport = new StdioServerTransport();
await server.connect(transport);
```

- [ ] **Step 2: ビルド**

Run: `cd plugins/clipboard/1.0.0 && npm run build`
Expected: `dist/index.js` が生成される

- [ ] **Step 3: 動作確認（手動テスト）**

Run: `echo "hello from test" | pbcopy && cd plugins/clipboard/1.0.0 && echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0.1.0"}}}' | node dist/index.js 2>/dev/null | head -1`
Expected: JSON-RPC の initialize レスポンスが返る（`"result":{"protocolVersion":...}` を含む）

- [ ] **Step 4: コミット**

```bash
git add plugins/clipboard/1.0.0/src/index.ts plugins/clipboard/1.0.0/dist/
git commit -m "feat: implement clipboard MCP server with read/write/history tools"
```

---

### Task 3: プラグイン設定ファイルの作成

**Files:**
- Create: `plugins/clipboard/1.0.0/.claude-plugin/plugin.json`
- Create: `plugins/clipboard/1.0.0/skills/clipboard/SKILL.md`

- [ ] **Step 1: plugin.json を作成**

`plugins/clipboard/1.0.0/.claude-plugin/plugin.json`:
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
  "keywords": ["clipboard", "macos", "pbcopy", "pbpaste", "mcp"],
  "mcpServers": {
    "clipboard": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/dist/index.js"]
    }
  }
}
```

- [ ] **Step 2: SKILL.md を作成**

`plugins/clipboard/1.0.0/skills/clipboard/SKILL.md`:
```markdown
---
name: clipboard
description: macOS clipboard read/write/history via MCP. Use when the user asks to read, copy, or check clipboard contents.
---

# Clipboard

Read, write, and track clipboard history on macOS.

## Available Tools

- `clipboard_read` — Get current clipboard contents
- `clipboard_write` — Write text to clipboard
- `clipboard_history` — Show write history for this session

## When to Use

- User says "クリップボードの内容を確認", "paste what I copied", "what's in my clipboard" → `clipboard_read`
- User says "これをコピーして", "copy this to clipboard", "クリップボードに入れて" → `clipboard_write`
- User says "さっきコピーしたもの", "clipboard history", "履歴を見せて" → `clipboard_history`
```

- [ ] **Step 3: コミット**

```bash
git add plugins/clipboard/1.0.0/.claude-plugin/plugin.json plugins/clipboard/1.0.0/skills/
git commit -m "feat: add plugin.json and clipboard skill"
```

---

### Task 4: マーケットプレイス登録と動作確認

**Files:**
- Modify: `~/workspace/dotfiles/config/claude/settings.json` (extraKnownMarketplaces, enabledPlugins)

- [ ] **Step 1: GitHub に push**

Run: `git push -u origin main`

- [ ] **Step 2: dotfiles の settings.json にマーケットプレイスを追加**

`config/claude/settings.json` の `extraKnownMarketplaces` に追加:
```json
"yuyamada-plugins": {
  "source": {
    "source": "git",
    "url": "git@github.com:yuyamada/claude-plugins"
  }
}
```

`enabledPlugins` に追加:
```json
"clipboard@yuyamada-plugins": true
```

- [ ] **Step 3: settings.json の変更をコミット（dotfiles リポ）**

```bash
cd ~/workspace/dotfiles
git add config/claude/settings.json
git commit -m "feat(claude): add yuyamada-plugins marketplace and enable clipboard plugin"
```

- [ ] **Step 4: プラグインを読み込む**

Claude Code で `/reload-plugins` を実行し、clipboard プラグインが認識されることを確認する。

- [ ] **Step 5: 動作確認**

Claude Code で以下を試す:
1. 「クリップボードの内容を見せて」→ `clipboard_read` が呼ばれる
2. 「"Hello World" をクリップボードにコピーして」→ `clipboard_write` が呼ばれる
3. 「クリップボードの履歴を見せて」→ `clipboard_history` が呼ばれる
