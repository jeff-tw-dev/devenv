---
name: plan-driven-dev
description: Run multi-round work in a repo against a durable PLAN.md task list, with every task traceable to the commits and files that implemented it, plus a maintained docs/ set and a CHECKPOINT.md for session handoff. Use when work spans more than one session or round, when the user asks for a plan file / task list / checkpoint, or when they want to see which files each task touched.
---

# Plan-driven development

A working discipline for work that outlives one session: the plan, the task
history and the reasoning all live in the repo, not in the context window.

Four artifacts, each answering a different question:

| File | Answers |
|---|---|
| `PLAN.md` | what is left, what is done |
| git history | which files each task actually touched, and why |
| `docs/` | how to build/test/reason about the result |
| `CHECKPOINT.md` | what a brand-new session needs to continue cheaply |

## 1. PLAN.md

On the first round, write `PLAN.md` as a markdown task list. Keep it current
every round — it is the source of truth, not a one-time artifact.

Each task line:

```
- [ ] T1: Parse the plan file | purpose: the UI needs structured tasks | files: src/plan.js, src/tasks.js | diff: +120/-8
```

- `T<n>` is a **stable id**. Never renumber, never reuse. Editing a title is
  fine; changing an id breaks every commit that already references it.
- `- [x]` marks done. Add tasks as you discover them — the list grows.
- `purpose` / `files` / `diff` are optional per line but cheap and worth it;
  `files` and `diff` are your own claim, git is the ground truth.
- **Cut tasks small: one task ≈ one focused commit.** A task that produces a
  400-line commit was two tasks.

Group with `##` headings when the list passes ~15 items.

## 2. Commits — task ↔ file traceability

The point is that months later `T7` can still tell you which files it changed
and why. That requires a link that survives history rewriting.

**Subject line: follow the repository's own convention.** Read the
`commit-style` skill if present, and check `git log --oneline -20` for the
existing shape (`feat(scope): …`, `area: …`, plain imperative). Do not impose a
foreign format on somebody's repo.

**Carry the task id in a trailer, not the subject:**

```
parser: split task lines on the pipe before reading the checkbox

- src/plan.js: pipe fields are optional, so parse them after the checkbox
- src/tasks.js: key tasks by id, falling back to ordinal + slug

Task: T3
```

- `Task: T3` is the durable link. It rides along through rebase, cherry-pick,
  amend and squash, because it is part of the message.
- **Never record commit hashes as the link.** A rebase rewrites every hash and
  the mapping silently goes stale.
- One `- <path>: <what changed and why>` line per changed file in the body.
  `git` already knows *what* the diff was; these lines carry *why*.
- One commit per task. If a commit spans two tasks, use two trailers
  (`Task: T3`, `Task: T4`) — but prefer splitting the commit.
- If the repo has no convention of its own, `T3: <imperative subject>` is a
  fine default — but still add the trailer, so tooling has one thing to read.

Reading it back, in any repo:

```bash
git log --grep='^Task: T3$' --format=%H          # commits for a task
git show --numstat --format= <sha>               # per-file +/- for one
git log --grep='^Task: T3$' --format=%b | grep '^- '   # the why lines
```

## 3. docs/

Maintain these as you work, not at the end. Each is short and answers one
question; an empty section is better than a stale one.

| File | Contains |
|---|---|
| `docs/HOW-TO-BUILD.md` | install, build, run — exact commands |
| `docs/HOW-TO-TEST.md` | how to verify, including manual smoke steps |
| `docs/HOW-IT-WORKS.md` | the architecture a newcomer needs |
| `docs/TRADE-OFFS.md` | what was chosen over what, and why |
| `docs/OBSTACLES.md` | what fought back, and how it was resolved |

`TRADE-OFFS.md` and `OBSTACLES.md` are the two that pay for themselves — they
are the things that cannot be re-derived from reading the code.

## 4. CHECKPOINT.md

Write it when the context budget is running low, when the user asks, or before
a deliberate handoff. It is written **for a session that has read nothing else**,
so optimize for tokens, not for prose:

- current task statuses, consistent with `PLAN.md`
- decisions already made (so they are not relitigated)
- the exact next step, concrete enough to start on
- the minimal metadata to continue: key file paths, commands, gotchas

Then stop feature work. A half-finished task plus an accurate checkpoint beats
a finished task nobody can pick up.

## Optional: autonomous rounds

When a runner (`/loop`, a scheduler, a harness) drives repeated rounds rather
than a human, end each round's final message with exactly one line:

```
STATUS: CONTINUE
```

or `STATUS: CONVERGED` when the work is complete and another round would add
nothing. Runners poll for this to decide whether to spend another round.

## Round loop

1. Read `PLAN.md` (and `CHECKPOINT.md` if present).
2. Take the next unchecked task.
3. Implement it; commit with the `Task: T<n>` trailer.
4. Tick it in `PLAN.md`; add any tasks the work revealed.
5. Update whichever `docs/` files the change invalidated.
6. Context running out → write `CHECKPOINT.md` and stop.
