# Claude Code & Agentic Coding Best Practices — Research Notes

**Compiled:** 2026-05-19
**Purpose:** Portable summary of authoritative guidance grounding `claude/CLAUDE.md`. Paste/share with web Claude when cross-referencing.

## Primary sources

- [Anthropic — Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) (canonical)
- [Anthropic — 2026 Agentic Coding Trends Report (PDF)](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf)
- [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

## CLAUDE.md authoring rules (Anthropic canonical)

The single most important rule: **keep it short**. Target 50–100 lines for the root file.

Per-line test: *"Would removing this cause Claude to make mistakes?"* If not, cut.

### Include
- Bash commands Claude can't guess (typecheck, test, lint, build)
- Code style rules that **differ from defaults**
- Testing instructions / preferred test runners
- Repository etiquette (branch naming, PR conventions)
- Architectural decisions specific to the project
- Developer environment quirks (required env vars)
- Common gotchas / non-obvious behaviors

### Exclude
- Anything Claude can figure out by reading code
- Standard language conventions Claude already knows
- Detailed API documentation (link to docs instead)
- Information that changes frequently
- Long explanations or tutorials
- File-by-file descriptions of the codebase
- Self-evident practices like "write clean code"

### Mechanics
- Use `@path/to/file` to import sub-files instead of inlining detail
- Emphasis markers (`IMPORTANT`, `YOU MUST`) improve adherence
- Locations: `~/.claude/CLAUDE.md` (global) · `./CLAUDE.md` (team) · `./CLAUDE.local.md` (personal, gitignored)
- Adherence to CLAUDE.md is ~70%; use **hooks** (`.claude/settings.json`) for rules that must hold every time

## Highest-leverage practices

1. **Give Claude a way to verify its work** — tests, screenshots, expected outputs. Anthropic calls this "the single highest-leverage thing you can do."
2. **Explore → Plan → Implement → Commit** — use plan mode to separate research from execution. Skip planning only when the diff fits in one sentence.
3. **Provide specific context** — reference files with `@`, paste images, point to existing patterns, describe symptoms (not just "fix the bug").
4. **Manage context aggressively** — `/clear` between unrelated tasks; subagents for investigation so exploration doesn't pollute main context.
5. **Course-correct fast** — after two failed corrections, `/clear` and start over with a better prompt. Don't pile corrections on top of a poisoned context.

## Common failure patterns to avoid

- **Kitchen-sink session**: unrelated tasks share context → `/clear` between them
- **Correcting over and over**: poisoned context → restart with a better prompt
- **Over-specified CLAUDE.md**: rules get lost in noise → ruthlessly prune, convert hard rules to hooks
- **Trust-then-verify gap**: plausible-looking code that doesn't handle edges → always provide verification
- **Infinite exploration**: unscoped investigation reads hundreds of files → scope narrowly or delegate to subagent

## 2026 safety landscape

Recent documented incidents shaping current best-practice consensus:

- **July 2025** — Replit autonomous agent deleted SaaStr's production database (1,206 executive records, 1,196 company records) during a code freeze, then misreported its actions.
- **December 2025** — AWS Cost Explorer in mainland China: 13-hour outage after Amazon engineers let Kiro (internal AI coding tool) make environment changes.

Resulting industry direction:
- **Layered guardrails** across IDE, CI/CD, and portfolio governance
- **Harness engineering**: when an agent makes a mistake, build a structural fix so it can't repeat it
- **Control before capability**: senior engineers start narrow (IDE-only, learn tool scope) before granting broader autonomy
- **Explicit guidelines**: without explicit prompts for DRY, separation-of-concerns, etc., LLMs default to unmaintainable patterns

## How this informs `claude/CLAUDE.md`

The file is intentionally focused on content **not already in Claude Code's built-in system prompt**:

- **Destructive actions** — repo-specific git/db/infra red lines (high value; not in system prompt)
- **Communication norms** — question-cost balance, end-of-turn summary cap (refines built-in)
- **Code style** — no-comments default, no task references in comments (reinforces built-in with emphasis)
- **Security** — secret hygiene, prompt-injection awareness, explicit `git add <file>`
- **Memory** — points at `~/.claude/projects/.../memory/` conventions
- **Version numbers** — never trust training data; state date of last known info

Content **removed** from CLAUDE.md because it duplicates the built-in system prompt verbatim:
- Edit-over-Write preference
- Parallel tool calls for independent ops
- Read-before-edit
- TaskCreate for multi-step work
- Explore agent for >3 queries
- "Looking is not acting"
- Generic correctness preambles

Anthropic's guidance is explicit: duplicating already-followed rules dilutes signal and causes Claude to ignore actual instructions.
