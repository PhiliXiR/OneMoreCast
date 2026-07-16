# Asset Batch Manifest

## Batch

- Issue: #105 Prepare a reviewable Home Water mountain kit
- Batch type: generated
- Review status: approved
- Intended use: Approved static mountain backdrop segments for composing the Home Water's inaccessible, nearly continuous all-around basin.

## Source

- Source tool, generator, or vendor: `tools/blender/generate_home_water_mountain_review_batch.py`
- Source URL or local reference: OneMoreCast repository; Blender-authored procedural low-poly source.
- License: Project-owned generated asset
- Attribution required: No
- Generated or imported by: Codex using Blender
- Date: 2026-07-16

## Contents

- Files:
  - `home_water_mountain_kit.blend` — editable source, containing four named segment collections and the review-only composition.
  - `home_water_mountain_north_ridge.glb` — approved higher, uneven north skyline; promoted to `assets/props/home_water/mountains/`.
  - `home_water_mountain_east_saddle.glb` — approved east profile with a pronounced low saddle; promoted to `assets/props/home_water/mountains/`.
  - `home_water_mountain_south_bench.glb` — approved lower south bench profile; promoted to `assets/props/home_water/mountains/`.
  - `home_water_mountain_west_shoulder.glb` — approved west shoulder with a second low saddle; promoted to `assets/props/home_water/mountains/`.
  - `home_water_mountain_basin_preview.png` — review composition of the four compatible segments around the Home Water.
  - `MANIFEST.md`
- Preview scene or screenshot: `home_water_mountain_basin_preview.png`; labels identify each compass segment.
- Known limitations: Promoted assets have no collision, LODs, texture atlas, placement scene, atmospheric effects, or Home Water integration. The review composition is not a playable Home Water change.

## Review Notes

- What should be evaluated: Whether the irregular low-saddle silhouettes make a believable enclosing mountain backdrop, and whether the muted slate-and-moss slopes, sparse forest masses, and restrained exposed rock match the Home Water art direction.
- Approval criteria: Four compatible, static low-poly segments read as a nearly continuous mountain backdrop without snow, generic terrain, procedural placement, or runtime-system dependency.
- Decision: Approved by the project owner on 2026-07-16. The four GLB outputs are promoted to `assets/props/home_water/mountains/`; the editable source, preview, and this manifest remain in the review batch.
- Follow-up issues: Authored Home Water placement must be handled separately.
