---
name: viz-decomposition
description:
  Decompose any body of domain knowledge (GPU architecture, databases, networking, biology, finance…) into a curriculum of many small interactive visualizations — the BrrrViz method. Use BEFORE building visualizations, when the user wants to "turn topic X into visualizations," "make a visual course/explainer series," "break this concept down visually," or asks how to structure an explorable-explanation site. Produces the decomposition map (chapters → one-claim pages → viz archetype per page); pair with the explorable-explanation skill to build each page.
metadata:
  author: marco
  version: "1.0.0"
  source: reverse-engineered from https://brrrviz.com (GPU programming, ~15 chapters / ~60 visualizations)
---

# Viz Decomposition — turning a domain into many small visualizations

The core insight from BrrrViz: **you don't visualize a domain, you visualize claims.**
A domain becomes teachable when it is shattered into ~5–60 single-sentence claims,
each claim gets exactly one visualization whose only job is to make that sentence
undeniable, and the claims are sequenced into a narrative arc.

## The pipeline

### Step 1 — Inventory the domain by knowledge type

Interview the domain (or the user) and sort everything into six buckets. Every
piece of domain knowledge falls into one, and each bucket maps to a different
visualization archetype later:

| Bucket | Question it answers | GPU example |
|---|---|---|
| **Structure** | What are the parts and how do they nest? | SM → cores/schedulers/SRAM; chip → 100s of SMs; memory tiers |
| **Behavior** | What happens over time, step by step? | kernel launch, warp scheduling, a race condition unfolding |
| **Constraints / costs** | What is expensive, limited, or traded off? | bandwidth vs compute, barrier cost, precision vs VRAM |
| **Failure modes** | How does it go wrong, and what does "wrong" look like? | divergence, bank conflicts, races, uncoalesced access |
| **Remedies** | The named fixes practitioners actually use | padding, swizzling, predication, tiling, coarsening |
| **Governing model** | The one quantitative framework that positions everything else | the roofline diagram |

### Step 2 — Extract claims, one per page

Rewrite every inventory item as a **single declarative sentence with a
consequence in it**. This sentence becomes the page's subtitle and its acceptance
test: the visualization succeeds iff a viewer would state this sentence
afterwards unprompted.

Good (from BrrrViz): "Every `__syncthreads()` forces all threads to wait for the
slowest one." / "Pad shared-memory rows so consecutive threads map to different
banks." Bad: "Understanding synchronization" (no claim), "Barriers, costs, and
alternatives" (three claims — split into three pages).

Rules:
- One claim = one page = one visualization. If the subtitle needs "and," split it.
- The claim states *cause → consequence*, not a topic.
- ~3–7 pages per chapter. A concept that yields only one claim is a single-page chapter (fine — BrrrViz has several).

### Step 3 — Group pages into chapters with a narrative arc

Chapters are not topic folders; their internal sections are named by **narrative
role**. The BrrrViz arc template, reused across nearly every chapter:

```
The ideal / baseline   →  what "working" looks like (1 page)
The problem            →  watch it fail, visibly and silently (1–2 pages)
The mechanism          →  why it fails, at the level below (1–2 pages)
The fixes              →  one page per named remedy (2–4 pages)
The tradeoff           →  what each fix costs (1 page)
```

Not every chapter needs all five beats, but **never skip "the problem"**: BrrrViz
always shows the wrong answer appearing (the race silently producing 8 instead of
30) *before* showing the fix. The failure creates the need the fix satisfies.

### Step 4 — Sequence chapters across the whole work

The book-level progression that generalizes:

1. **Anatomy** — the nouns. What the machine/system physically is. Start with a
   contrast against something the learner already knows (BrrrViz: CPU vs GPU).
2. **Dynamics** — the verbs. How work actually flows through the anatomy.
3. **The governing model** — the map. One quantitative chart that tells the
   learner *which* problem they have (roofline: memory-bound vs compute-bound).
   Place it early: every later chapter locates itself on this map.
4. **Failure modes** — one chapter per distinct way things go wrong, each with
   the Step-3 arc.
5. **Capstone case studies** — a real worked problem optimized in successive
   steps, where each step *reuses a concept from an earlier chapter* (BrrrViz:
   Reduction chains atomics → tree → shared memory → packing → bank conflicts →
   coarsening). This is the spaced-repetition payoff of the whole structure.
6. **Applied arc** (optional "Act 2") — the domain's flagship applications,
   promised on a roadmap even before built.

### Step 5 — Assign each page a viz archetype

Match the claim's knowledge type (Step 1 bucket) to an interaction archetype:

| Archetype | Use for | Interaction | BrrrViz example |
|---|---|---|---|
| **Zoomable anatomy** | Structure | click a part → descend a level; hover → definition card with real numbers | chip → click SM → SM internals |
| **Step-through state machine** | Behavior, failure modes | Prev/Next through 4–8 discrete states, one caption per state; each state titled like a claim ("Thread 1 writes", "Wrong answer") | race condition, atomicAdd lock sequence, tiled matmul phases |
| **Contrast pair** | Remedies, design tradeoffs | same input rendered side-by-side under two policies; the *difference* is the lesson | packed vs strided, linear vs swizzled, CPU vs GPU execution |
| **Parameter → consequence** | Constraints, sensitivity | slider/drag with **discrete named regimes**, not a continuum (stride 1/2/4/8/16/32, each labeled "2-way conflict…") | stride slider, draggable roofline dot, precision picker |
| **Annotated model chart** | Governing model | hover to preview a definition, click to pin; drag a "your system is here" marker | the roofline diagram |
| **Race/timeline view** | Concurrency, scheduling | parallel lanes with stalls, overlaps, and idle time made visible as empty space | host/device timeline, warp scheduler, streams |

### Step 6 — Apply the house style rules

- **Real numbers, always.** "~100× faster," "3.35 TB/s on H100," "log₂(N)
  rounds." Anchor every claim quantitatively; use real-world entities as data
  points (BrrrViz plots GPT-3 and Llama 3 on the VRAM chart).
- **Disclose simplifications inline.** "Simplified for teaching: this viz only
  follows threadIdx.x." Teach the clean mental model; footnote where reality
  diverges. Never silently lie.
- **Idle = visible.** Waste is the villain of most systems domains. Render idle
  lanes, masked threads, and empty pipeline slots as conspicuous dead space.
- **Vocabulary on the diagram,** not in a glossary: hover-to-preview,
  click-to-pin definition chips at the moment the term appears.
- **Silent failure must be watchable.** If the domain's bugs don't crash (races,
  precision drift, stale caches), the viz's job is to let the user *see* the
  wrong value appear with no error raised.

## Deliverable format

Produce the decomposition as a map before building anything:

```
Act 1 — <Fundamentals>
  Ch 1  <Anatomy>            "one-sentence chapter thesis"
    [Baseline]  page-slug — Claim sentence.           (archetype: contrast pair)
    [The problem] …
  Ch 2  …
Act 2 — <Applied> (roadmap)
```

Then build pages one at a time — each page is a self-contained unit, ideal for
the **explorable-explanation** skill (one file, SVG-first, sliders/steppers).

## Worked mini-example (transfer test: relational databases)

- Anatomy: pages → heap file → buffer pool → B-tree (zoomable anatomy)
- Dynamics: one SELECT's journey; WAL write path (step-through)
- Governing model: cost model / seq-scan-vs-index crossover chart (annotated chart, draggable selectivity dot)
- Failure modes: lost update (step-through, wrong balance appears silently) → lock waits (timeline) → deadlock (state machine)
- Fixes: isolation levels (contrast pair: same interleaving under READ COMMITTED vs SERIALIZABLE), MVCC (step-through)
- Capstone: one slow query optimized in 5 steps — add index → covering index → denormalize → partition — each step re-using an earlier chapter's concept, with measured ms at every step.
