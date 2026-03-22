# Design: Mobile Permission Approval for Claude Code

**Date:** 2026-03-22
**Reference:** https://zenn.dev/schroneko/articles/claude-code-remote-control-and-mobile-notification

## Goal

Allow approving Claude Code permission prompts (and responding to idle/elicitation events) from an iPhone, even when away from the Mac.

## Architecture

```
Claude Code (Mac)
  └─ Notification hook
       └─ bark-notify.sh (AES-256-CBC encrypted)
            └─ Bark API → iPhone Bark app
                          └─ tap notification
                               └─ mobile browser → Claude Code Remote UI
                                    └─ approve / deny / input
```

Claude Code's built-in `remoteControlAtStartup` feature establishes an outbound WebSocket to Anthropic's servers, making the session accessible from any browser without port-forwarding or a tunnel.

## Components

### 1. Bark iOS app

- Install from App Store (ID: 1403753865)
- Provides a device key used to target push notifications
- Supports AES-256-CBC encrypted payloads for privacy

### 2. `~/.claude/hooks/bark-notify.sh`

Downloaded from the author's Gist:
```
https://gist.githubusercontent.com/schroneko/200f8529bb6d34b030eb114ec63532a4/raw/bark-notify.sh
```

Implements AES-256-CBC encryption before sending the notification payload to the Bark API. Not tracked in dotfiles (machine-specific, downloaded at setup time).

### 3. `~/.claude/settings.local.json` (machine-specific, not in dotfiles)

```json
{
  "env": {
    "BARK_DEVICE_KEY": "<device key from Bark app>",
    "BARK_ENCRYPT_KEY": "<32-char hex key>",
    "BARK_ENCRYPT_IV": "<16-char hex IV>"
  }
}
```

Keys are generated once per machine via `openssl rand`.

### 4. `config/claude/settings.json` — Notification hook addition

Add a second entry to the existing `Notification` array (the existing `osascript` entry is kept):

```json
{
  "matcher": "permission_prompt|idle_prompt|elicitation_dialog",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/hooks/bark-notify.sh"
    }
  ]
}
```

Triggers on three events:
- `permission_prompt` — Claude requests tool permission
- `idle_prompt` — Claude is waiting for user input
- `elicitation_dialog` — Claude is asking a clarifying question

### 5. `~/.claude.json` (machine-specific, not in dotfiles)

```json
{ "remoteControlAtStartup": true }
```

Enables the remote control WebSocket at every session start. Can alternatively be toggled via `/config` inside Claude Code.

## File Ownership

| File | Location | Tracked in dotfiles? |
|------|----------|---------------------|
| `settings.json` (hook entry) | `config/claude/settings.json` | Yes |
| `bark-notify.sh` | `~/.claude/hooks/` | No (downloaded at setup) |
| `settings.local.json` (env vars) | `~/.claude/settings.local.json` | No (sensitive) |
| `~/.claude.json` | `~/.claude.json` | No (machine-specific) |

## Setup Steps

1. Install Bark on iPhone from the App Store
2. Open Bark app, copy the device key from the home screen
3. Generate encryption credentials on the Mac:
   ```bash
   openssl rand -hex 16   # BARK_ENCRYPT_KEY (use 32 chars)
   openssl rand -hex 8    # BARK_ENCRYPT_IV (use 16 chars)
   ```
4. In the Bark app, navigate to push notification encryption settings:
   - Algorithm: AES256
   - Mode: CBC
   - Enter Key and IV from step 3
5. Create `~/.claude/settings.local.json` with the three env vars
6. Download and chmod the hook script:
   ```bash
   curl -o ~/.claude/hooks/bark-notify.sh \
     https://gist.githubusercontent.com/schroneko/200f8529bb6d34b030eb114ec63532a4/raw/bark-notify.sh
   chmod +x ~/.claude/hooks/bark-notify.sh
   ```
7. Add the Bark Notification hook entry to `config/claude/settings.json`
8. Enable remote control: add `{"remoteControlAtStartup": true}` to `~/.claude.json`
   or run `/config` inside Claude Code
9. Test: trigger a permission prompt and verify iPhone receives the notification

## Out of Scope

- Replacing the existing `osascript` notification (kept as-is for when at the Mac)
- Self-hosting Bark server (the public Bark API is sufficient)
- Adding the bark-notify.sh script itself to dotfiles
