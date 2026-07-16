# Asset Batch Manifest

## Batch

- Issue: #101 Create a reviewable Home Water pine kit
- Batch type: generated
- Review status: approved
- Intended use: Approved runtime Pine kit for composing the inaccessible Home Water tree line.

## Source

- Source tool, generator, or vendor: `tools/blender/generate_home_water_pine_review_batch.py`
- Source URL or local reference: OneMoreCast repository; Blender-authored procedural low-poly source.
- License: Project-owned generated asset
- Attribution required: No
- Generated or imported by: Codex using Blender
- Date: 2026-07-15

## Contents

- Files:
  - `home_water_pine_kit.blend` — editable Blender source with named variant and review collections.
  - `home_water_pine_landmark.glb` — approved tall landmark pine runtime output, promoted to `assets/foliage/`.
  - `home_water_pine_standard.glb` — approved standard pine runtime output, promoted to `assets/foliage/`.
  - `home_water_pine_leaning.glb` — approved smaller leaning pine runtime output, promoted to `assets/foliage/`.
  - `home_water_pine_tree_line_preview.png` — review composition showing all variants layered together.
  - `MANIFEST.md`
- Preview scene or screenshot: `home_water_pine_tree_line_preview.png` (labels identify the landmark, standard, and leaning variants in their intended layered composition).
- Known limitations: The promoted GLBs have no collision, LODs, wind animation, placement scene, or baked texture atlas. Editable source and visual evidence remain in `_review`.

## Review Notes

- What should be evaluated: Landmark, standard, and leaning silhouettes; layered scale hierarchy; restrained bark/needle PBR direction; weathered Home Water character at a far-bank reading distance.
- Approval criteria: Reads as a compatible weathered low-poly Pine kit for the Home Water tree line, without becoming a generic foliage pack, photoreal forest, or storybook asset.
- Decision: Approved by the project owner on 2026-07-15. The three GLB outputs are promoted to `assets/foliage/`; keep the editable source, preview, and this manifest in the review batch.
- Follow-up issues: None.
