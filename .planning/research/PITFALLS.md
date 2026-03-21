# Pitfalls & Risks: Claude Code Autonomous Configuration

**Analysis Date:** 2026-03-21

## High-Severity Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| `Bash(sed:*)` is an RCE vector (CVE-2025-66032) | `sed -e` executes shell commands | Fix before expanding other permissions |
| `git push --force` auto-approved | Irreversible history rewrite | Keep in deny block always |
| `git add .` commits secrets/large binaries | Credential leak, bloated repo | Use explicit file staging in skills |
| MCP tools (Slack/Notion) are injection entry points | Prompt injection via trusted content → secret exfil | Keep network allowlist — never disable |
| Unversioned `gsd-*.md` agents not in git | Injected instruction persists with no audit trail | Version-control agent definitions |

## Non-Negotiable Safeguards

Even in full YOLO mode:
- **Keep sandbox network allowlist** — prevents exfiltration to attacker servers
- **Keep `tool-access.log` hook** — audit trail
- **Keep `deny` block** with: `git push --force`, `rm -rf`, `sudo`, `curl|bash`
- **Never globally disable sandbox**

## Safe to Expand

- `Bash(git *)` with deny rules — safe with sandbox in place
- `Bash(npm/npx/node *)` — safe if network allowlist maintained
- `Bash(gh *)` — safe with deny for destructive ops

---
*Pitfalls research: 2026-03-21*
