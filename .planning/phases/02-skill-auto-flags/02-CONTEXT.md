# Phase 2: Skill Auto Flags - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Add `--auto` flag support to the `commit` and `pr` skills so they execute end-to-end without any confirmation stops when the flag is passed. Existing interactive behavior (no `--auto`) must remain unchanged.

Skills in scope: `config/claude/skills/commit/SKILL.md`, `config/claude/skills/pr/SKILL.md`

</domain>

<decisions>
## Implementation Decisions

### Confirmation gates to skip

**commit skill — gates to skip when --auto:**
- Branch check confirmation (Step 1: "Propose branch name, confirm before creating")
- Commit message confirmation (Step 3: "Show message, wait for confirmation")
- Push confirmation (Step 4: "Ask about push")

**pr skill — gates to skip when --auto:**
- Push confirmation (Step 1: "Ask whether to push first")
- PR content review gate (Step 3: "Show title/body, wait for confirmation")
- Open-in-browser prompt (Step 5: minor gate, skip in auto mode)

### Unrelated files behavior (commit --auto)
- **D-01:** Do NOT stage unrelated files — exclude silently. No error, no prompt. Only stage files clearly related to the current task (same logic as interactive mode Step 2, but without asking the user when ambiguous).

### Branch behavior (commit --auto)
- **D-02:** Claude's discretion — handle sensibly. Reasonable approaches: auto-create branch from a generated name if on default branch, or proceed on current branch if already on a feature branch.

### Output verbosity (--auto)
- **D-03:** Claude's discretion — produce enough output to confirm what was done (useful for subagent debugging), but no interactive prompts.

### Existing interactive behavior
- When `--auto` is NOT passed, all existing steps and confirmation gates remain exactly as they are. Zero behavior change for the non-auto path.

### Claude's Discretion
- Exact branch naming strategy in auto mode (if auto-creation needed)
- Where in the skill file the `--auto` flag is documented and checked
- Whether --auto detection uses frontmatter, inline check, or injected context

</decisions>

<specifics>
## Specific Ideas

- No specific UX references — standard CLI `--auto` / `--no-interactive` convention is fine
- Skills are plain Markdown files — the flag check is prose-based, not code

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skill files to modify
- `config/claude/skills/commit/SKILL.md` — Current commit skill: 4 steps, 4 confirmation gates
- `config/claude/skills/pr/SKILL.md` — Current pr skill: 5 steps, 3 confirmation gates

### Requirements
- `.planning/REQUIREMENTS.md` §SKIL-01, SKIL-02 — Exact requirement wording for each skill

### Project conventions
- `config/claude/rules/git.md` — Conventional Commits format used for commit messages and PR titles

</canonical_refs>

<code_context>
## Existing Code Insights

### Skill file structure
- Both skills are Markdown with YAML frontmatter (`allowed-tools`, `description`, `name`)
- Steps are prose instructions — Claude follows them as a recipe
- `!` prefix in frontmatter runs shell commands at skill load time to inject live state
- `--auto` detection will be prose-based ("If `--auto` was passed...") not code

### Established Patterns
- Confirmation gates are phrased as "confirm with the user" / "wait for confirmation" — removing these in auto mode means replacing with "proceed directly"
- `allowed-tools` in frontmatter controls which bash commands are pre-approved — no change needed (same tools, just no confirmation prompts)

### Integration Points
- These skills are invoked by orchestrators (e.g. GSD execute-phase via commit skill)
- `--auto` is the standard GSD flag convention for non-interactive execution

</code_context>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-skill-auto-flags*
*Context gathered: 2026-03-21*
