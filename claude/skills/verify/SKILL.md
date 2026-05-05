---
name: verify
description: Run build, tests, and show git state. Use before committing or pushing to confirm everything is clean.
---

Run the following checks in sequence and report results clearly:

1. **Build** — run `go build ./...` (or the appropriate build command for this project). If it fails, stop and report the error.

2. **Tests** — run `go test -race -count=1 ./...` (or the project's test command). Report pass/fail and any failing test output.

3. **Git state** — run `git status` and `git diff --stat HEAD`. Report:
   - Any uncommitted changes
   - What is staged vs unstaged
   - Current branch and how many commits ahead/behind of origin

4. **Summary** — give a one-line verdict: "Ready to commit", "Tests failing", "Uncommitted changes", etc.

If any step fails, stop there and do not proceed to the next step. Be direct — do not pad the output.
