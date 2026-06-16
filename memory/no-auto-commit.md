---
name: no-auto-commit
description: User handles git commit/push themselves — never commit or push automatically
metadata:
  type: feedback
---

For the cardnews project, do NOT run `git commit` or `git push` automatically. The user (gabeenya) will handle all commits and pushes themselves. Make code changes only, then tell them what to commit.

**Why:** User explicitly asked on 2026-06-16 to stop auto-committing after the initial setup phase.
**How to apply:** Edit/write files as needed, then stop. Mention which files changed so they can commit, but don't stage/commit/push unless they explicitly ask in that message.
