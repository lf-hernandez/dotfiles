# Claude Code config

Tracked pieces of `~/.claude/` — global instructions, settings, custom agents,
skills, hooks, and the statusline script. Everything else in `~/.claude/`
(credentials, session history, projects, todos, caches, telemetry) is
deliberately excluded.

## Layout

```
claude/
├── CLAUDE.md                              → ~/.claude/CLAUDE.md
├── settings.json                          → ~/.claude/settings.json
├── statusline-command.sh                  → ~/.claude/statusline-command.sh
├── agents/code-improvement-advisor.md     → ~/.claude/agents/...
├── skills/review/SKILL.md                 → ~/.claude/skills/review/SKILL.md
├── skills/verify/SKILL.md                 → ~/.claude/skills/verify/SKILL.md
└── hooks/validate-destructive.sh          → ~/.claude/hooks/...
```

## Restore on a fresh machine

```sh
mkdir -p ~/.claude/agents ~/.claude/skills/review ~/.claude/skills/verify ~/.claude/hooks
cp CLAUDE.md settings.json statusline-command.sh ~/.claude/
cp agents/code-improvement-advisor.md ~/.claude/agents/
cp skills/review/SKILL.md ~/.claude/skills/review/
cp skills/verify/SKILL.md ~/.claude/skills/verify/
cp hooks/validate-destructive.sh ~/.claude/hooks/
chmod +x ~/.claude/statusline-command.sh ~/.claude/hooks/validate-destructive.sh
```

Then run `claude` and re-authenticate (Claude account login + any MCP
servers). `~/.claude/.credentials.json` and `~/.claude.json` are
machine/session-specific and intentionally not tracked.
