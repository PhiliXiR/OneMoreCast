# Asset Batch Manifest

## Batch

- Issue: #105 Prepare a reviewable Home Water mountain kit
- Batch type: generated
- Review status: proposed
- Intended use: Candidate static mountain backdrop segments for composing the Home Water's inaccessible, nearly continuous all-around basin after visual approval.

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
  - `home_water_mountain_north_ridge.glb` — candidate higher, uneven north skyline.
  - `home_water_mountain_east_saddle.glb` — candidate east profile with a pronounced low saddle.
  - `home_water_mountain_south_bench.glb` — candidate lower south bench profile.
  - `home_water_mountain_west_shoulder.glb` — candidate west shoulder with a second low saddle.
  - `home_water_mountain_basin_preview.png` — review composition of the four compatible segments around the Home Water.
  - `MANIFEST.md`
- Preview scene or screenshot: `home_water_mountain_basin_preview.png`; labels identify each compass segment.
- Known limitations: Candidate assets have no collision, LODs, texture atlas, placement scene, atmospheric effects, or runtime integration. The GLBs are intentionally not promoted to `assets/`; the review composition is not a playable Home Water change.

## Review Notes

- What should be evaluated: Whether the irregular low-saddle silhouettes make a believable enclosing mountain backdrop, and whether the muted slate-and-moss slopes, sparse forest masses, and restrained exposed rock match the Home Water art direction.
- Approval criteria: Four compatible, static low-poly segments read as a nearly continuous mountain backdrop without snow, generic terrain, procedural placement, or runtime-system dependency.
- Decision: Pending human visual approval.
- Follow-up issues: Promotion and authored Home Water placement must be handled separately after approval.
