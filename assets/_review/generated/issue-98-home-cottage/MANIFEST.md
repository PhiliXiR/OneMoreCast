# Asset Batch Manifest

## Batch

- Issue: #98 Create a reviewable Home Cottage Blender asset set
- Batch type: generated
- Review status: proposed
- Intended use: Candidate exterior and roofless interior source art for the Home Cottage, with an in-world Mara Vale presentation.

## Source

- Source tool, generator, or vendor: `tools/blender/generate_home_cottage_review_batch.py`
- Source URL or local reference: OneMoreCast repository; generated in Blender 5.1.2.
- License: Project-owned generated asset
- Attribution required: No
- Generated or imported by: Codex using Blender 5.1.2
- Date: 2026-07-15

## Contents

- Files:
  - `home_cottage_source.blend` — editable source containing named exterior, interior, Mara, and review collections.
  - `home_cottage_exterior_shell.glb` — porch-facing weathered exterior shell.
  - `home_cottage_interior_roofless.glb` — 6 m by 5 m roofless single-room interior.
  - `mara_vale_idle_ready.glb` — simple low-poly in-world Mara presentation.
  - `home_cottage_exterior_preview.png`
  - `home_cottage_interior_preview.png`
  - `MANIFEST.md`
- Preview scene or screenshot: `home_cottage_exterior_preview.png` and `home_cottage_interior_preview.png`
- Known limitations: Review-only visual asset; no collisions, LODs, interactions, or runtime placement scenes. Mara includes a restrained root-bone idle action, but needs final animation and gameplay integration. The material palette uses named procedural PBR materials only—no baked lighting or texture atlas.

## Review Notes

- What should be evaluated: Cottage silhouette and dock-facing porch door; interior door-to-desk-to-Mara route; roofless camera readability; stove, shelves, bed nook, and practical fishing props; muted weathered material palette and Mara scale.
- Approval criteria: A modest, weathered shared working lakeside home that can be explicitly approved before any candidate export is promoted into runtime assets.
- Decision: Pending human visual review. Do not promote this batch into normal asset folders.
- Follow-up issues: None.
