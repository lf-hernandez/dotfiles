---
name: review
description: Review code through seven lenses in the current session. Pass a file path or leave blank to review recent changes.
argument-hint: "[file path or blank for git diff]"
---

Review $ARGUMENTS using all seven lenses below. If no file is given, run `git diff HEAD` and review the changes.

Work through each lens in order. Security first — it has the highest cost if missed.

---

**1. Security**
Injection risks, auth/authz gaps, secrets in code or logs, unsafe defaults, trust boundary violations, dependency risks.

**2. Performance**
Time/space complexity, unnecessary iterations, N+1 patterns, blocking calls, memory leaks, I/O inefficiency.

**3. Test Coverage**
What is untested, missing edge cases, error path coverage, brittle or tautological assertions, test isolation issues.

**4. Best Practices**
Error handling, SOLID principles, API design, design pattern misuse, maintainability red flags.

**5. Idiomatic Correctness**
Is this how the language/framework is meant to be used? Fighting the type system, reinventing built-ins, unnatural patterns for this ecosystem.

**6. Pragmatic/Practical**
Is the complexity justified by the problem? Over-abstracted, under-abstracted, solving a hypothetical instead of the actual problem, obvious simplifications missed.

**7. Readability**
Naming, structure, cognitive load, duplication, misleading comments.

---

For each finding include: the lens, severity (critical / warn / minor), the exact code, and a one-line explanation of why it matters.

If a lens has nothing to flag, say "nothing to flag" — do not skip it silently.

End with a single verdict line: what is the most important thing to fix and why.
