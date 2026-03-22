# Mobile Permission Approval Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable iPhone push notifications and remote control so Claude Code permission prompts can be approved from anywhere.

**Architecture:** Bark (iOS push notification app) receives encrypted notifications from a shell hook. Claude Code's built-in `remoteControlAtStartup` provides a browser-accessible session UI. The existing `osascript` notification is preserved alongside Bark.

**Tech Stack:** Bark iOS app, AES-256-CBC (OpenSSL), Claude Code Notification hooks, Claude Code remote control

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `~/.claude/hooks/bark-notify.sh` | Create (download) | Sends encrypted push notifications to Bark API |
| `~/.claude/settings.local.json` | Create | Machine-specific env vars (device key, encryption credentials) |
| `~/.claude.json` | Modify | Enable `remoteControlAtStartup` |
| `config/claude/settings.json` | Modify | Add Bark Notification hook entry |

---

### Task 1: Set up Bark on iPhone

**Files:** None (manual)

- [ ] **Step 1: Install Bark**

  Install from the App Store: search "Bark" (ID: 1403753865) or open:
  `https://apps.apple.com/app/bark-customed-notifications/id1403753865`

- [ ] **Step 2: Get device key**

  Open the Bark app. On the home screen, tap the server URL — it looks like:
  `https://api.day.app/YOUR_DEVICE_KEY/`

  Copy `YOUR_DEVICE_KEY` (a string of ~22 alphanumeric chars). Save it somewhere temporarily.

- [ ] **Step 3: Generate encryption credentials on Mac**

  ```bash
  openssl rand -hex 16   # → 32 hex chars → use as BARK_ENCRYPT_KEY
  openssl rand -hex 8    # → 16 hex chars → use as BARK_ENCRYPT_IV
  ```

  Example output:
  ```
  a3f1c2d4e5b6a7f8c9d0e1f2a3b4c5d6   ← BARK_ENCRYPT_KEY (32 chars)
  b1c2d3e4f5a6b7c8                   ← BARK_ENCRYPT_IV (16 chars)
  ```

- [ ] **Step 4: Configure encryption in Bark app**

  In Bark → Settings → Push Notification Encryption:
  - Algorithm: **AES256**
  - Mode: **CBC**
  - Key: paste the 32-char key from Step 3
  - IV: paste the 16-char IV from Step 3

---

### Task 2: Create `~/.claude/settings.local.json`

**Files:**
- Create: `~/.claude/settings.local.json`

- [ ] **Step 1: Check if file already exists**

  ```bash
  cat ~/.claude/settings.local.json 2>/dev/null || echo "does not exist"
  ```

- [ ] **Step 2: Create or merge the file**

  If the file does not exist, create it:
  ```bash
  cat > ~/.claude/settings.local.json << 'EOF'
  {
    "env": {
      "BARK_DEVICE_KEY": "YOUR_DEVICE_KEY_HERE",
      "BARK_ENCRYPT_KEY": "YOUR_32_CHAR_KEY_HERE",
      "BARK_ENCRYPT_IV": "YOUR_16_CHAR_IV_HERE"
    }
  }
  EOF
  ```

  If the file already exists, merge `env` keys manually (do not overwrite existing content).

- [ ] **Step 3: Fill in the actual values**

  Edit the file and replace the three placeholder values with credentials from Task 1.

- [ ] **Step 4: Verify JSON is valid**

  ```bash
  jq . ~/.claude/settings.local.json
  ```
  Expected: pretty-printed JSON with no errors.

---

### Task 3: Download `bark-notify.sh`

**Files:**
- Create: `~/.claude/hooks/bark-notify.sh`

- [ ] **Step 1: Ensure hooks directory exists**

  ```bash
  mkdir -p ~/.claude/hooks
  ```

- [ ] **Step 2: Download the script**

  ```bash
  curl -o ~/.claude/hooks/bark-notify.sh \
    https://gist.githubusercontent.com/schroneko/200f8529bb6d34b030eb114ec63532a4/raw/bark-notify.sh
  ```

- [ ] **Step 3: Make executable**

  ```bash
  chmod +x ~/.claude/hooks/bark-notify.sh
  ```

- [ ] **Step 4: Verify the script is present and executable**

  ```bash
  ls -la ~/.claude/hooks/bark-notify.sh
  ```
  Expected: `-rwxr-xr-x` permissions.

- [ ] **Step 5: Inspect the script before running**

  ```bash
  head -30 ~/.claude/hooks/bark-notify.sh
  ```
  Check how the script expects to be invoked (arguments? env vars only?). Look for any built-in test or example usage in the comments.

- [ ] **Step 6: Smoke-test the script**

  Run it as documented by the script itself. If it takes no arguments and reads from env vars:
  ```bash
  ~/.claude/hooks/bark-notify.sh
  ```
  Expected: A push notification appears on iPhone.
  If it fails, verify the three env vars in `settings.local.json` are set correctly and the Bark app encryption settings (AES256/CBC + matching Key/IV) are configured.

---

### Task 4: Add Bark Notification hook to `settings.json`

**Files:**
- Modify: `config/claude/settings.json`

- [ ] **Step 1: Locate the existing Notification section**

  The current `Notification` array in `settings.json` has one entry (the `osascript` hook at `permission_prompt`). We will add a second entry.

- [ ] **Step 2: Add the Bark hook entry**

  In `config/claude/settings.json`, find the `"Notification"` array and add a second object after the existing `osascript` entry:

  ```json
  "Notification": [
    {
      "matcher": "permission_prompt",
      "hooks": [
        {
          "type": "command",
          "command": "osascript -e 'display notification \"Approve waiting\" with title \"Claude Code\"'"
        }
      ]
    },
    {
      "matcher": "permission_prompt|idle_prompt|elicitation_dialog",
      "hooks": [
        {
          "type": "command",
          "command": "~/.claude/hooks/bark-notify.sh"
        }
      ]
    }
  ]
  ```

- [ ] **Step 3: Validate JSON**

  ```bash
  jq . config/claude/settings.json > /dev/null && echo "valid"
  ```
  Expected: `valid`

- [ ] **Step 4: Commit**

  ```bash
  git add config/claude/settings.json
  git commit -m "feat(claude): add Bark push notification hook for mobile approval"
  ```

---

### Task 5: Enable remote control

**Files:**
- Modify: `~/.claude.json`

- [ ] **Step 1: Check if `~/.claude.json` exists**

  ```bash
  cat ~/.claude.json 2>/dev/null || echo "does not exist"
  ```

- [ ] **Step 2: Add `remoteControlAtStartup`**

  If the file does not exist:
  ```bash
  echo '{"remoteControlAtStartup": true}' > ~/.claude.json
  ```

  If the file exists, add the key manually (do not overwrite other content):
  ```bash
  jq '. + {"remoteControlAtStartup": true}' ~/.claude.json > /tmp/claude.json && mv /tmp/claude.json ~/.claude.json
  ```

- [ ] **Step 3: Verify**

  ```bash
  jq .remoteControlAtStartup ~/.claude.json
  ```
  Expected: `true`

  > Note: `~/.claude.json` is machine-specific and not tracked in dotfiles. No git commit is needed for this step.

---

### Task 6: End-to-end verification

- [ ] **Step 1: Start a new Claude Code session**

  Open a new Claude Code session. The remote control URL should appear in the session output or be accessible via `/config`.

- [ ] **Step 2: Trigger a permission prompt**

  Ask Claude to run a command that requires approval, e.g. a command not in the `allow` list.

- [ ] **Step 3: Verify iPhone notification**

  Within a few seconds, a Bark notification should appear on iPhone with the permission request details.

- [ ] **Step 4: Verify remote access from iPhone browser**

  Tap the notification to open the remote URL in Safari. Confirm the Claude Code session UI is visible and the permission prompt can be approved from the phone.
