# Asset Batch Manifest

## Batch

- Issue: #67 Create and approve the animated Dock Bluegill asset
- Batch type: generated
- Review status: proposed
- Intended use: First authored Dock Bluegill and reference form for later small-bodied fish.

## Source

- Source tool, generator, or vendor: `tools/blender/generate_dock_bluegill.py` executed with Blender.
- Source URL or local reference: One More Cast repository.
- License: Project-owned generated asset.
- Attribution required: No.
- Generated or imported by: Codex; revised against side-profile references from Illinois DNR and the U.S. National Park Service.
- Date: 2026-07-11.

## Contents

- Files: `dock_bluegill.blend`, `dock_bluegill.glb`, `dock_bluegill_palette.png`, `dock_bluegill_preview.png`, `dock_bluegill.json`, and this manifest.
- Preview scene or screenshot: `fish/dock_bluegill_review_preview.tscn` staged by `tools/validate_dock_bluegill_review.ps1`; `dock_bluegill_preview.png`.
- Known limitations: Low-to-mid-poly review candidate only; no collision, LODs, sound, species variants, or gameplay integration. Runtime promotion is prohibited until approval.

## Review Notes

- What should be evaluated: deep laterally compressed silhouette, spiny dorsal/anal fins, textured olive-to-yellow body and bars, dark opercular flap behind the eye, skeleton reuse, and the three named clips.
- Approval criteria: Blender source opens; GLB imports under Godot Compatibility; `calm_swim`, `struggle_surge`, and `landed_presentation` run in the preview; the reviewer records approval on issue #67.
- Decision: Pending human review.
- Follow-up issues: #68 (integration), if approved.
