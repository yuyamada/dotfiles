# Claude Code Devcontainer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Docker コンテナ内で Claude Code を安全に実行するための Dockerfile と compose.yml を作成する

**Architecture:** 公式 `ghcr.io/anthropics/claude-code:latest` イメージを継承し、compose.yml でホストの Claude Code 設定を読み取り専用マウント。コンテナ起動時にファイアウォールを初期化し、`--dangerously-skip-permissions` を安全に使える環境を提供する。

**Tech Stack:** Docker, Docker Compose

---

### Task 1: Create Dockerfile

**Files:**
- Create: `config/claude/devcontainer/Dockerfile`

- [ ] **Step 1: Create devcontainer directory**

Run: `mkdir -p config/claude/devcontainer`

- [ ] **Step 2: Write Dockerfile**

```dockerfile
FROM ghcr.io/anthropics/claude-code:latest

RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    ripgrep \
    fd-find \
    && rm -rf /var/lib/apt/lists/*
```

- [ ] **Step 3: Verify Dockerfile syntax**

Run: `docker build --check config/claude/devcontainer/`
Expected: No syntax errors

- [ ] **Step 4: Commit**

```bash
git add config/claude/devcontainer/Dockerfile
git commit -m "feat(claude): add devcontainer Dockerfile based on official image"
```

---

### Task 2: Create compose.yml

**Files:**
- Create: `config/claude/devcontainer/compose.yml`

- [ ] **Step 1: Write compose.yml**

```yaml
services:
  claude:
    build: .
    volumes:
      # Claude Code settings (read-only)
      - ../../settings.json:/home/node/.claude/settings.json:ro
      - ../../rules:/home/node/.claude/rules:ro
      - ../../skills:/home/node/.claude/skills:ro
      - ../../hooks:/home/node/.claude/hooks:ro
      - ../../CLAUDE.md:/home/node/.claude/CLAUDE.md:ro
      # workspace
      - ~/workspace:/workspace
    working_dir: /workspace
    user: node
    environment:
      - CLAUDE_CODE_OAUTH_TOKEN
      - GH_TOKEN
    cap_add:
      - NET_ADMIN
      - NET_RAW
    stdin_open: true
    tty: true
    entrypoint: ["/bin/sh", "-c", "sudo /usr/local/bin/init-firewall.sh && exec zsh"]
```

- [ ] **Step 2: Validate compose file**

Run: `docker compose -f config/claude/devcontainer/compose.yml config --quiet`
Expected: No errors (exit code 0)

- [ ] **Step 3: Commit**

```bash
git add config/claude/devcontainer/compose.yml
git commit -m "feat(claude): add devcontainer compose.yml with mount and auth config"
```

---

### Task 3: Build and smoke test

- [ ] **Step 1: Build the image**

Run: `docker compose -f config/claude/devcontainer/compose.yml build`
Expected: Image builds successfully, ripgrep and fd-find installed

- [ ] **Step 2: Start the container**

Run: `docker compose -f config/claude/devcontainer/compose.yml up -d`
Expected: Container starts, firewall initializes

- [ ] **Step 3: Verify tools are available**

Run: `docker compose -f config/claude/devcontainer/compose.yml exec claude sh -c "claude --version && rg --version && fdfind --version && gh --version && git --version"`
Expected: All commands return version info

- [ ] **Step 4: Verify settings are mounted**

Run: `docker compose -f config/claude/devcontainer/compose.yml exec claude cat /home/node/.claude/settings.json | head -5`
Expected: Shows beginning of settings.json content

- [ ] **Step 5: Verify firewall is active**

Run: `docker compose -f config/claude/devcontainer/compose.yml exec claude sudo iptables -L -n | head -20`
Expected: Shows iptables rules with DROP default policy

- [ ] **Step 6: Stop the container**

Run: `docker compose -f config/claude/devcontainer/compose.yml down`

- [ ] **Step 7: Commit (if any adjustments were made)**

Only if files were modified during smoke testing.
