---
name: 3d-orientation
description: >-
  Discipline for getting orientation, axes, and rotations right when writing
  code or reasoning about 3D models and scenes. Use this WHENEVER a task
  involves 3D space — placing/rotating objects, cameras, lights, lookAt,
  quaternions or Euler angles, importing/exporting models (glTF, FBX, OBJ,
  USD), or converting between tools (Three.js, Babylon.js, R3F, Blender, Unity,
  Unreal, Godot, Maya, WebGL/WebGPU, OpenGL, DirectX). Trigger it even when the
  user doesn't say "orientation" — any time something might end up sideways,
  mirrored, upside-down, facing the wrong way, spinning the wrong direction, or
  scaled wrong. 只要牽涉 3D 方向、座標系、旋轉、模型匯入匯出或跨工具轉換,就使用本 skill。
---

# 3D Orientation Discipline

## Why this exists

Directional bugs in 3D almost never come from bad math. They come from
**silently assuming a coordinate convention**. "Up", "forward", "right", and
"positive rotation" are not universal — every tool picks its own, and the
conventions contradict each other (Y-up vs Z-up, right-handed vs left-handed,
metres vs centimetres, +Z-forward vs −Z-forward). When you guess, you're right
about half the time, which is exactly how you get a model lying on its side or
a camera orbiting backwards.

The fix is to stop treating orientation as intuition and start treating it as
an **explicit, verified artifact**. Four rules do most of the work.

---

## Rule 1 — Write the Coordinate Contract before any code

Before writing spatial code, state the target's conventions out loud as a
comment block. Pull the values from `references/conventions.md`. Never leave any
field as "probably the default".

```
// COORDINATE CONTRACT
// Target        : Three.js (r160)
// Up axis       : +Y
// Handedness    : right-handed
// Forward       : camera looks down -Z; a Mesh's lookAt points +Z at target
// Units         : 1 unit = 1 metre (my choice, stated so I stay consistent)
// Rotation      : quaternions internally; Euler order 'XYZ', radians
// UV origin     : (0,0) bottom-left in GLSL sampling; glTF textures top-left
// Front face    : counter-clockwise winding
```

Writing this first turns a hidden assumption into something you can check. If
you can't fill a field, that's the bug you're about to hit — go find out.

## Rule 2 — Anchor reasoning to a concrete reference, and state the rotation rule

Never reason about "forward" in the abstract. Pin it to something physical:

- **A canonical figure at the origin**: a person standing on the ground plane,
  head toward +up, face toward +forward, right arm toward +right. Map every
  direction you talk about back to this figure.
- **An RGB gizmo**: X = red, Y = green, Z = blue (the convention Blender, Unity,
  Godot, etc. all use). When you say "+Z", picture the blue arrow.

For rotation *sign*, state the rule explicitly every time instead of guessing:

- **Right-handed system**: point your right thumb along the +axis; your fingers
  curl in the direction of *positive* rotation (counter-clockwise when the axis
  points toward you).
- **Left-handed system** (Unity, Unreal, DirectX): use the left hand — positive
  rotation is clockwise when the axis points toward you.

Getting handedness wrong is the #1 cause of "it spins the wrong way" and of
inverted normals / wrong-side culling.

## Rule 3 — Compute rotations, don't intuit them

Guessing an Euler triple like `(0, 90, 0)` is where models hallucinate. Instead:

- Write the **basis vectors** you want (new forward, up, right), then build a
  matrix or quaternion from them. `right = normalize(cross(up, forward))` in a
  right-handed system (swap operands or negate for left-handed — derive it, and
  verify with the hand rule from Rule 2).
- Prefer engine helpers over hand-rolled Euler math: `Matrix4.lookAt` /
  `Quaternion.setFromUnitVectors` / `quatFromForwardUp`, not three chained
  `rotateX/Y/Z` calls whose order you're unsure of.
- Use **quaternions** for composing/interpolating rotations; treat Euler angles
  as input/output only, and always name the order (XYZ, ZXY, …) explicitly.

## Rule 4 — Build a verification harness before declaring success

You cannot see the scene, so make the scene tell you if it's right. Before
saying a 3D task is done, add cheap ground truth:

- Drop **RGB axis arrows** at the origin (X-red, Y-green, Z-blue) so up/forward
  are visible.
- Place **labeled reference markers**: a small cube at `+X`, a sphere at `+Y`, a
  cone at `+Z`, and one object at a known position like `(2, 0, 0)`.
- **Print world positions / directions** of key objects and check the signs
  against the Coordinate Contract.
- When a renderer is available, **render one frame from a known camera and
  inspect it** (rasterise to an image and actually look), rather than trusting
  that the transform "looks right" in code.

If any marker lands where the contract says it shouldn't, stop and fix the
convention — don't patch it with a mystery `* -1`.

---

## Cross-tool conversion: only via an explicit axis map

Most import/export bugs are a Z-up↔Y-up or handedness flip applied by accident.
Never eyeball it — write the mapping as an equation.

**Blender (Z-up, right-handed) → glTF / Three.js (Y-up, right-handed):**
`(x, y, z)_blender → (x, z, -y)_gltf` — i.e. rotate −90° about X.

**Y-up (glTF) → Z-up (Blender/Unreal):** `(x, y, z) → (x, -z, y)`, i.e. +90°
about X.

**Right-handed → left-handed (e.g. glTF → Unity):** negate one axis (Unity
flips Z: `z → -z`) *and* reverse triangle winding, or normals/culling invert.

Full per-tool table and more recipes are in `references/conventions.md` — read
it whenever the target isn't already in your Coordinate Contract.

---

## Recipes for the operations that go wrong most

**Make object A face object B.** Decide which local axis is A's *modeled* front,
then reconcile it with the engine's lookAt convention — they often differ. In
Three.js, `camera.lookAt` points local −Z at the target, but `mesh.lookAt`
points local +Z. If your model was authored facing a different axis, apply a
fixed offset quaternion once rather than fighting it per-frame.

**Orbit a camera around a target.** Rotate a position *offset* vector around the
world up axis, then set `camera.position = target + offset` and `camera.lookAt(
target)`. Bugs here are almost always: wrong up axis, or a left/right-handed
sign flip making it orbit backwards — check against Rule 2.

**Rotate 90° about a world axis vs a local axis.** These are different
operations. World: `q_world * q_object`. Local: `q_object * q_local`. State
which one you mean; "rotate it 90°" is ambiguous until you say world or local.

**Model imports lying on its side.** Almost always a Z-up asset in a Y-up engine.
Fix at the source (correct export up-axis) or apply the −90°-about-X map above —
not a random per-object tweak.

**Model imports mirrored / inside-out.** A handedness flip without a matching
winding reversal. Flip winding order or normals, or negate the axis consistently
across geometry *and* transforms.

---

## Pitfalls quick reference

| Symptom | Likely cause | Fix |
|---|---|---|
| Object on its side after import | Z-up asset in Y-up engine | Rotate −90° about X, or fix export up-axis |
| Everything mirrored / inside-out | Handedness flip w/o winding reversal | Reverse winding or flip one axis consistently |
| Rotation goes the wrong way | Wrong handedness assumption for sign | Re-derive with the hand rule (Rule 2) |
| Object faces away from target | Engine lookAt axis ≠ model's front axis | Offset quaternion; verify which axis is "forward" |
| Backfaces / holes in the mesh | Winding vs cull-face mismatch | Match winding order to the front-face convention |
| Textures upside-down | UV origin top-left vs bottom-left | Flip V (`v → 1 - v`) or set the loader's flipY |
| Model 100× too big/small | Unit mismatch (cm vs m) | Apply scale; Unreal = cm, glTF/most = m |
| Euler rotation looks scrambled | Wrong Euler order assumed | Name and match the order; prefer quaternions |

---

## The loop, in one line

Contract → anchor + hand-rule → compute (quaternions) → **verify with a gizmo/
render** → only then done. If verification fails, fix the *convention*, never
sprinkle sign flips.
