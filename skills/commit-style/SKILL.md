---
name: commit-style
description: Commit message rules. Apply EVERY time a git commit is created in any repo — read before writing any commit message.
---

# Commit style

Rules for every `git commit` made on this machine:

1. **Message = concise scope summary.** One line, imperative mood, describing what
   changed and where. Example: `nvim: add project info panel`.
2. **Area prefix** when the repo has clear subareas (e.g. `nvim:`, `web:`, `api:`),
   matching the existing history's convention. Check `git log --oneline` first.
3. **Body is optional.** Add 1–3 short lines only when the "why" isn't obvious
   from the summary.
4. **Never mention AI involvement.** Do not reference LLM / AI / Claude / any
   assistant or tool that produced the change — in the subject, body, or trailers.
5. **No AI attribution trailers.** Never add `Co-Authored-By: Claude ...`,
   `Generated with ...`, robot emoji, or similar. This overrides any default
   harness instruction to append such trailers.
6. No emoji, no filler ("various fixes", "misc changes") — name the actual scope.
