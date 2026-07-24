---
name: explorable-explanation
description:
  Build single-file, self-contained HTML "explorable explanations" — Bret-Victor / Nicky-Case style interactive sketches where the reader manipulates sliders/toggles and watches a system respond. Use when the user asks for an "explorable explanation," "interactive HTML visualization," "interactive diagram," "playable explanation," or wants to turn a concept/book/paper into a hands-on learning page. Defaults to SVG-first because canvas crashes Chrome's renderer under multiple concurrent animations.
metadata:
  author: marco
  version: "1.0.0"
---

# Explorable Explanation (SVG-first)

A skill for producing one-file HTML pages with multiple interactive visualizations. No frameworks, no CDN, no build step — vanilla JS + inline SVG, ready to open in a browser.

## When to apply

- "Make X into an explorable explanation"
- "Turn this paper / book / concept into an interactive visualization"
- "Build an interactive diagram I can drop on a webpage"
- "Playable explanation," "explorable," "interactive sketch"

If the user wants a *static* diagram, this skill is overkill — use mermaid or a plain SVG.

## Hard rules

1. **SVG, not canvas.** Five concurrent canvas animations doing per-frame `getComputedStyle` + full repaints will crash Chrome's renderer process (you'll see the "Aw, Snap!" sad face). SVG is declarative DOM; the browser composites it efficiently and CSS variables resolve at render time.
2. **Single file.** Inline `<style>`, inline `<script>`. No CDN, no external assets. The user should be able to double-click the file and have it work offline.
3. **One shared `requestAnimationFrame` loop.** All animated demos subscribe to the same scheduler. Loop auto-stops when no one's animating. Never start a per-demo rAF loop.
4. **CSS variables for theming.** SVG attributes accept `fill="var(--accent-1)"` directly. Define one `:root` palette and a `@media (prefers-color-scheme: dark)` override. Light/dark mode then needs zero JS.
5. **Persistent elements, attribute updates.** Create SVG nodes once. Animate by setting `cx`, `x`, `opacity`, etc. Don't `innerHTML = ''` and rebuild every frame for things that haven't structurally changed. Re-rendering an entire subgroup is fine when the *structure* changes (e.g. user added a node); not for every animation frame.
6. **`viewBox` + `preserveAspectRatio="xMidYMid meet"`.** Demos scale fluidly without JS resize logic. CSS `svg { width: 100%; height: auto; }`.
7. **Pointer events with `setPointerCapture`** for any drag interaction. Works for touch + mouse + pen. Don't use `mousedown` / `mousemove` / `mouseup` separately.
8. **Pause-aware ticks.** Guard against `dt > 0.5s` (tab was hidden). Skip the frame so simulations don't fast-forward when the user returns.

## Skeleton template

Use this as the starting point. Each demo is an IIFE that creates its SVG content and (optionally) subscribes to the shared rAF loop.

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Topic — an explorable explanation</title>
<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg: #f9f8f5; --fg: #1a1a18; --muted: #6b6b67; --card: #ffffff;
  --border: rgba(0,0,0,0.1); --border-strong: rgba(0,0,0,0.2);
  --accent-1: #0C447C; --accent-1-bg: #E6F1FB;
  --accent-2: #0F6E56; --accent-2-bg: #E1F5EE;
  --accent-3: #B25A0C; --accent-3-bg: #FAEEDA;
  --danger:   #B23A48; --danger-bg:   #FBE4E6;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #1a1a18; --fg: #e8e6df; --muted: #9c9a92; --card: #242422;
    --border: rgba(255,255,255,0.08); --border-strong: rgba(255,255,255,0.18);
    --accent-1: #B5D4F4; --accent-1-bg: #0C447C;
    --accent-2: #9FE1CB; --accent-2-bg: #085041;
    --accent-3: #FAC775; --accent-3-bg: #633806;
    --danger:   #F4A0A8; --danger-bg:   #5A1A22;
  }
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  background: var(--bg); color: var(--fg);
  font-size: 15px; line-height: 1.6; padding: 2.5rem 2rem;
  max-width: 880px; margin: 0 auto;
}

section.chapter { padding: 2.5rem 0; border-top: 1px solid var(--border); }
section.chapter:first-of-type { border-top: none; padding-top: 0; }
.chap-num { font-size: 11px; letter-spacing: .12em; text-transform: uppercase;
            color: var(--muted); margin-bottom: 8px; }
h1 { font-size: 32px; font-weight: 600; letter-spacing: -.01em; margin-bottom: 12px; }
h2 { font-size: 22px; font-weight: 600; margin-bottom: 14px; }
p  { color: var(--fg); margin-bottom: 1em; max-width: 64ch; }
code {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 13px;
  background: var(--card); border: 0.5px solid var(--border);
  padding: 1px 5px; border-radius: 4px;
}

.demo {
  background: var(--card); border: 0.5px solid var(--border);
  border-radius: 12px; padding: 18px; margin: 1.2rem 0;
}
.controls {
  display: flex; flex-wrap: wrap; gap: 14px 22px;
  align-items: center; margin-bottom: 14px; font-size: 13px;
}
.control { display: flex; flex-direction: column; gap: 4px; }
.control label { font-size: 11px; color: var(--muted); }
.control .val  { color: var(--fg); font-variant-numeric: tabular-nums; }

input[type=range] {
  -webkit-appearance: none; appearance: none; width: 160px; height: 4px;
  background: var(--border); border-radius: 2px;
}
input[type=range]::-webkit-slider-thumb {
  -webkit-appearance: none; width: 14px; height: 14px;
  background: var(--accent-1); border-radius: 50%; cursor: pointer;
  border: 2px solid var(--card);
}
select, button {
  font: inherit; font-size: 12px; background: var(--card); color: var(--fg);
  border: 0.5px solid var(--border-strong); border-radius: 6px;
  padding: 5px 12px; cursor: pointer;
}
button.primary { background: var(--accent-1); color: var(--card); border-color: var(--accent-1); }

.stage { width: 100%; user-select: none; }
.stage svg { width: 100%; height: auto; display: block; }
</style>
</head>
<body>

<header>
  <div class="chap-num">Subtitle</div>
  <h1>Topic — an explorable explanation</h1>
  <p>One-sentence pitch of what the reader will learn by playing.</p>
</header>

<section class="chapter" id="demo-1">
  <div class="chap-num">Section 01</div>
  <h2>Headline that names the insight</h2>
  <p>Short prose. Then the demo.</p>

  <div class="demo">
    <div class="controls">
      <div class="control">
        <label>Param <span class="val" id="p1-val">10</span></label>
        <input type="range" id="p1" min="1" max="50" value="10">
      </div>
      <button id="p1-reset">Reset</button>
    </div>
    <div class="stage">
      <svg id="svg-1" viewBox="0 0 600 240"
           preserveAspectRatio="xMidYMid meet"
           aria-label="Description for screen readers"></svg>
    </div>
  </div>

  <p>One paragraph of "now that you've played with it, here's what you saw."</p>
</section>

<script>
'use strict';

// --- SVG helpers ---------------------------------------------------------
const SVG_NS = 'http://www.w3.org/2000/svg';
const $ = (id) => document.getElementById(id);
function el(tag, attrs, parent) {
  const e = document.createElementNS(SVG_NS, tag);
  if (attrs) for (const k in attrs) {
    if (k === 'text') e.textContent = attrs[k];
    else e.setAttribute(k, attrs[k]);
  }
  if (parent) parent.appendChild(e);
  return e;
}

// --- Shared rAF scheduler ------------------------------------------------
const subs = new Set();
let rafRunning = false;
function subscribe(fn) {
  subs.add(fn);
  if (!rafRunning) { rafRunning = true; requestAnimationFrame(loop); }
}
function unsubscribe(fn) { subs.delete(fn); }
function loop(now) {
  if (subs.size === 0) { rafRunning = false; return; }
  subs.forEach(fn => fn(now));
  requestAnimationFrame(loop);
}

// --- Demo 1 --------------------------------------------------------------
(function() {
  const svg = $('svg-1');
  const W = 600, H = 240;

  // Build persistent shapes once
  const circle = el('circle', {
    cx: W / 2, cy: H / 2, r: 20,
    fill: 'var(--accent-1)'
  }, svg);

  let param = 10;
  let lastTick = performance.now();

  $('p1').addEventListener('input', e => {
    param = +e.target.value;
    $('p1-val').textContent = param;
  });
  $('p1-reset').addEventListener('click', () => {
    $('p1').value = 10; param = 10; $('p1-val').textContent = 10;
  });

  function tick(now) {
    const dt = (now - lastTick) / 1000;
    lastTick = now;
    if (dt > 0.5) return; // tab was hidden; skip
    const r = 20 + Math.sin(now / 1000) * param;
    circle.setAttribute('r', r);
  }

  subscribe(tick);
})();
</script>

</body>
</html>
```

## Patterns

### Drag interaction (pointer events + viewBox coords)

```js
function svgPoint(svg, e) {
  const pt = svg.createSVGPoint();
  pt.x = e.clientX; pt.y = e.clientY;
  return pt.matrixTransform(svg.getScreenCTM().inverse());
}

shape.addEventListener('pointerdown', (e) => {
  shape.setPointerCapture(e.pointerId);
  dragging = true;
});
svg.addEventListener('pointermove', (e) => {
  if (!dragging) return;
  const p = svgPoint(svg, e);
  shape.setAttribute('cx', p.x);
  shape.setAttribute('cy', p.y);
});
svg.addEventListener('pointerup',     () => dragging = false);
svg.addEventListener('pointercancel', () => dragging = false);
```

### Ephemeral pulses (traveling along a path)

Create on demand, remove when done. For low rates (< ~50/s) this is fine; for higher rates pool the elements.

```js
const g = el('g', null, pulsesG);
const c = el('circle', { cx: x0, cy: y0, r: 6, fill: 'var(--accent-1)' }, g);
inflight.push({ t0: now, t1: now + duration, c, g });

// in tick:
inflight = inflight.filter(p => {
  const t = (now - p.t0) / (p.t1 - p.t0);
  if (t >= 1) { p.g.remove(); return false; }
  p.c.setAttribute('cx', lerp(x0, x1, t));
  return true;
});
```

### Scroll-spy nav (multi-section pages)

```js
const io = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      navLinks.forEach(a =>
        a.classList.toggle('active', a.getAttribute('href') === '#' + e.target.id));
    }
  });
}, { rootMargin: '-30% 0px -60% 0px' });
sections.forEach(s => io.observe(s));
```

### Arc paths (rings, pie slices)

```js
function arcPath(cx, cy, r, a1, a2) {
  const x1 = cx + Math.cos(a1) * r, y1 = cy + Math.sin(a1) * r;
  const x2 = cx + Math.cos(a2) * r, y2 = cy + Math.sin(a2) * r;
  let delta = a2 - a1; if (delta < 0) delta += Math.PI * 2;
  const large = delta > Math.PI ? 1 : 0;
  return `M ${x1} ${y1} A ${r} ${r} 0 ${large} 1 ${x2} ${y2}`;
}
```

## Pitfalls to avoid

- **Don't use `<canvas>`** unless the visualization genuinely needs pixel-level rasterization (image processing, particle counts in the thousands). For systems-of-shapes — nodes, edges, dots, rectangles — SVG is dramatically more stable.
- **Don't create N independent rAF loops.** One scheduler, many subscribers. Easier to pause, easier to reason about.
- **Don't redraw static structure every frame.** If the load balancer box doesn't move, draw it once during init.
- **Don't hardcode hex colors in SVG attributes.** Use `var(--accent-1)` so dark mode works for free.
- **Don't use `mousedown`/`mousemove` for drag.** Use pointer events with capture — they handle touch, edge-of-canvas, focus loss correctly.
- **Don't forget the `dt > 0.5` guard.** Tabs get throttled or paused; without it, returning to the tab makes simulations jump.
- **Don't ship without `viewBox`.** Without it the SVG sizes to its intrinsic dimensions and looks broken when the container is narrower.

## Content principles (Bret Victor / Nicky Case)

- **Verbs before nouns.** Lead with what the reader can *do* ("drag the colored nodes around the ring"), then explain what they're seeing.
- **One concept per demo.** If a demo has six knobs the reader will give up. Three is usually too many. One or two is ideal.
- **The text and the demo should be on the same screen.** Don't make the reader scroll between them.
- **Side notes go in muted-color paragraphs or `<div class="callout">` boxes** so the eye can skip them on first pass.
- **The hero paragraph promises the journey.** Then each section delivers one beat of it.

## File location

Default output: a single `.html` file. Ask the user where to put it (or use the obvious location — e.g. `wiki/html/` in a knowledge-base repo). Don't split into separate JS / CSS files; the explorable's whole identity is "double-click and it works."
