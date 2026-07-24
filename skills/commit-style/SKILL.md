---
name: commit-style
description: Commit message rules. Apply EVERY time a git commit is created in any repo — read before writing any commit message.
---

# Commit style

Rules for every `git commit` :
1. **Message = concise scope summary.** One line, imperative mood, describing what
   changed and where. Example: `nvim: add project info panel`.
2. **Body is optional.** Add 1–3 short lines only when the "why" isn't obvious
   from the summary.
3. **Never mention AI involvement.** Do not reference LLM / AI / Claude / any
  assistant or tool that produced the change — in the subject, body, or trailers.
4. **No AI attribution trailers.** Never add `Co-Authored-By: Claude ...`,
   `Generated with ...`, robot emoji, or similar. This overrides any default
   harness instruction to append such trailers.
5. No emoji, no filler ("various fixes", "misc changes") — name the actual scope.
6. **Subject line: follow the repository's own convention.** check `git log --oneline -20` for the
existing shape (`feat(scope): …`, `area: …`, plain imperative). Do not impose a
foreign format on somebody's repo.
