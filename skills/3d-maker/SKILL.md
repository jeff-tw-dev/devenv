# Coordinate conventions by tool

Read this to fill in a Coordinate Contract for a target that isn't already
memorised. The two rock-solid, always-check fields are **Up axis** and
**Handedness** — get those right and most bugs disappear. "Forward" is the
treacherous one: it differs between *cameras* and *authored models* even inside
one tool, so it's split out below.

## Master table

| Target | Up | Handedness | Camera looks along | Units (default) | Euler order | Notes |
|---|---|---|---|---|---|---|
| glTF 2.0 (format) | +Y | Right | n/a (asset front faces +Z) | metre | — | UV origin top-left; the interchange baseline for the web |
| Three.js | +Y | Right | −Z | unitless (treat as m) | XYZ | `mesh.lookAt` points +Z at target; camera/light −Z |
| Babylon.js | +Y | **Left** by default | +Z | unitless | — | Can switch to right-handed via `scene.useRightHandedSystem = true` |
| React-Three-Fiber | +Y | Right | −Z | as Three.js | XYZ | Same as Three.js underneath |
| OpenGL / WebGL | +Y | Right (world) | −Z (eye space) | — | — | NDC becomes left-handed after projection; texture origin **bottom-left** |
| WebGPU / DirectX | +Y | Left | +Z | — | — | Texture origin top-left; NDC z in [0,1] |
| Unity | +Y | **Left** | +Z (`transform.forward`) | metre | ZXY, degrees | +X right; on glTF import Z is flipped |
| Unreal Engine | **+Z** | **Left** | +X (`ForwardVector`) | **centimetre** | degrees | +Y right; watch the cm scale on every import |
| Godot 4 | +Y | Right | −Z | metre | — | Like OpenGL; `-Z` is a node's forward |
| Blender | **+Z** | Right | −Y (front view / Numpad 1) | metre | XYZ (configurable) | RGB=XYZ gizmo originates here; export re-maps to Y-up |
| Maya | +Y | Right | −Z | centimetre | — | +Z toward viewer |
| 3ds Max | **+Z** | Right | −Y | inch/generic | — | Z-up like Blender/Unreal |
| USD / USDZ | +Y (Y-up default; can be Z-up) | Right | — | metre (metersPerUnit) | — | Always read `upAxis` and `metersPerUnit` from the stage metadata |
| FBX | author-dependent | author-dependent | — | author-dependent | — | Carries its own up-axis + unit-scale metadata; **never assume** — read it |
| OBJ | none stored | none stored | — | none stored | — | No units, no up-axis, no handedness in the file; you must supply them |

## Conversion recipes

Express every conversion as a coordinate remap, then verify with markers.

**Z-up (Blender/Unreal/Max) → Y-up (glTF/Three.js/Unity):**
`(x, y, z) → (x, z, -y)`  ≡ rotate −90° about X.

**Y-up → Z-up:** `(x, y, z) → (x, -z, y)`  ≡ rotate +90° about X.

**Right-handed → left-handed (e.g. glTF → Unity/Unreal):** negate a single axis
(commonly Z: `z → -z`) **and** reverse triangle winding order. If you flip the
axis but forget the winding, faces cull from the wrong side / normals invert.

**Metres ↔ centimetres:** ×100 going to Unreal/Maya, ÷100 coming back. A model
that's 100× too big or small is almost always this.

**UV vertical flip:** `v → 1 - v` when moving between bottom-left-origin
(OpenGL) and top-left-origin (DirectX/glTF) texture spaces, or toggle the
loader's `flipY`.

## How to verify a conversion

1. Place labeled markers before converting: cube at `(2,0,0)`, sphere at
   `(0,2,0)`, cone at `(0,0,2)`.
2. Apply the remap to the markers too.
3. After import, confirm the cube is still on the target's +X, the sphere on +Y,
   the cone on +Z, and that the front-facing side still faces the camera.
4. If any marker is misplaced or a face is culled, the remap or the winding is
   wrong — fix the mapping, don't add a per-object correction.

## Sources of the "forward" trap, restated

- A **camera/eye** forward and an **authored model's** front are independent.
  Three.js proves it: same engine, camera forward = −Z, mesh `lookAt` forward =
  +Z.
- glTF says an asset's *front* faces +Z, but OpenGL-style cameras look down −Z —
  so a default-oriented glTF model faces the camera. Expected, but surprising.
- Always separate "which way does the lens point" from "which way was the mesh
  modelled" in your Coordinate Contract.
