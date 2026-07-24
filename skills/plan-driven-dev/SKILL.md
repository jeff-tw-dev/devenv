---
name: plan-driven-dev
description: Run multi-round work in a repo against a durable PLAN.md task list, starting each round by analysing the project into a PROJECT-STRUCTURE.md map (or, for an empty repo, confirming the stack with the user first), with every task traceable to the commits and files that implemented it, plus a maintained docs/ set and a CHECKPOINT.md for session handoff. Use when work spans more than one session or round, when the user asks for a plan file / task list / checkpoint / project structure, or when they want to see which files each task touched.
---

# Plan-driven development

A working discipline for work that outlives one session: the plan, the task
history and the reasoning all live in the repo, not in the context window.

Five artifacts, each answering a different question:

| File | Answers |
|---|---|
| `PROJECT-STRUCTURE.md` | what this project *is* — stack, layout, conventions |
| `PLAN.md` | what is left, what is done |
| git history | which files each task actually touched, and why |
| `docs/` | how to build/test/reason about the result |
| `CHECKPOINT.md` | what a brand-new session needs to continue cheaply |

## 0. Orient — PROJECT-STRUCTURE.md

**Do this before touching `PLAN.md` or any code, every round.** You cannot plan
against a project you have not looked at. The output is `PROJECT-STRUCTURE.md`,
the map every later step reads instead of re-deriving the layout from scratch.

**Existing project** — analyse before you assume:

1. **Read the manifests.** Every one you find: `Makefile`, `package.json`,
   `CMakeLists.txt`, `pyproject.toml` / `requirements.txt`, `go.mod`,
   `Cargo.toml`, `pom.xml`, `README.md`, and anything under `docs/`. They tell
   you the *declared* stack, scripts and entry points.
2. **Read the code, layer by layer.** Walk the tree top-down and open enough of
   each layer to confirm what it actually holds — entry points, config, the core
   modules, where tests live. The manifest is a claim; the code is the ground
   truth, and the two drift.
3. **Write `PROJECT-STRUCTURE.md`** capturing:
   - **Stack** — language(s), package manager, framework(s), UI library,
     build/test tooling.
   - **Layout** — the top-level dirs and what each layer is responsible for;
     where entry points, config and tests sit.
   - **Structure style** — how modules are organised (layered, feature-sliced,
     domain-driven, flat …) and the naming conventions in force.
   - **Seams** — how the layers depend on each other; the boundaries a change
     must respect.

**Empty / greenfield project** — decide before you scaffold. Ask the user to
confirm the architecture first, then write the initial `PROJECT-STRUCTURE.md`
from their answers. At minimum settle:

- programming language
- package / dependency manager
- framework(s)
- project-structure style (layered, feature-sliced, monorepo …)
- UI library (if there is a UI)

Do not guess these into existence — a wrong foundational choice is the most
expensive thing to unwind later.

**On later rounds** it already exists: re-read it, reconcile it against the
current tree, and update the deltas rather than rebuilding from zero. When it is
missing or has gone stale, do the full sweep again.

## 1. PLAN.md

On the first round, write `PLAN.md` as a markdown task list. Keep it current
every round — it is the source of truth, not a one-time artifact.

Each task line:

```
- [ ] Parse the plan file | purpose: structured tasks for the UI | files: src/plan.js, src/tasks.js | diff: +120/-8
```

- `purpose` is the **stable anchor** — the durable link to the commits that
  implement the task (see §2). Word it once, for the *intent*, not the
  implementation; intent rarely changes, so the phrase stays put even as the
  title, files and code churn. Refining the title is free; rewording `purpose`
  breaks every commit that already references it, so avoid it.
- **Each `purpose` must be distinct.** It is the key you grep on — two tasks
  sharing a phrase collide and become indistinguishable in history.
- `- [x]` marks done. Add tasks as you discover them — the list grows.
- `files` / `diff` are optional per line but cheap and worth it; they are your
  own claim, git is the ground truth.
- **Cut tasks small: one task ≈ one focused commit.** A task that produces a
  400-line commit was two tasks.

Group with `##` headings when the list passes ~15 items.

## 2. Commits — task ↔ file traceability

The point is that months later a task can still tell you which files it changed
and why. That requires a link that survives history rewriting — and the task's
`purpose` is that link.

### Commit style

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

**Carry the task's `purpose` in a trailer, not the subject:**

```
parser: split task lines on the pipe before reading the checkbox

- src/plan.js: pipe fields are optional, so parse them after the checkbox
- src/tasks.js: key tasks by purpose, falling back to ordinal + slug

Task: structured tasks for the UI
```

- `Task: <purpose>` is the durable link — the value is the task's `purpose`,
  copied **verbatim** from the matching `PLAN.md` line. It rides along through
  rebase, cherry-pick, amend and squash, because it is part of the message.
- **Never record commit hashes as the link.** A rebase rewrites every hash and
  the mapping silently goes stale.
- One `- <path>: <what changed and why>` line per changed file in the body.
  `git` already knows *what* the diff was; these lines carry *why*.
- One commit per task. If a commit spans two tasks, use two trailers
  (`Task: …`, `Task: …`) — but prefer splitting the commit.
- The subject still follows the repo's own convention (§ Commit style); the
  trailer is the one thing tooling reads, so always add it.

Reading it back, in any repo:

```bash
git log --grep='^Task: structured tasks for the UI$' --format=%H          # commits for a task
git show --numstat --format= <sha>                                        # per-file +/- for one
git log --grep='^Task: structured tasks for the UI$' --format=%b | grep '^- '   # the why lines
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

1. **Orient (§0):** read `PROJECT-STRUCTURE.md`; reconcile it with the tree, or
   build it if it is missing. For an empty project, confirm the architecture
   with the user first.
2. Read `PLAN.md` (and `CHECKPOINT.md` if present).
3. Take the next unchecked task.
4. Implement it; commit with the `Task: <purpose>` trailer, copied verbatim
   from the task's `purpose`.
5. Tick it in `PLAN.md`; add any tasks the work revealed.
6. Update whichever `docs/` files the change invalidated; refresh
   `PROJECT-STRUCTURE.md` if the change moved a layer or added a dependency.
7. Context running out → write `CHECKPOINT.md` and stop.
