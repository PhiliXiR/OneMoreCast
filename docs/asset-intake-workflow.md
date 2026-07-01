# Asset Intake Workflow

OneMoreCast owns game-ready assets, curated review batches, and approved output
from generation or vendor selection. 3DCodexPipeline owns reusable tools that
produce or process those assets.

## Folders

- `assets/_review/generated/`: curated generated batches tied to an active issue.
- `assets/_review/vendor/`: curated third-party pack candidates tied to an active issue.
- `assets/_scratch/`: disposable local experiments. This folder is ignored.
- `assets/docks/`, `assets/foliage/`, `assets/fish/`, `assets/lures/`,
  `assets/props/`, `assets/materials/`: approved game-ready assets.

`assets/_review/` contains source and candidate files for human review, so it
has a `.gdignore` file and is not imported by the Godot editor. Promote only
approved runtime assets into the normal asset folders.

## Intake Rules

Disposable experiments stay in `assets/_scratch/` and are not committed.

Commit a review batch only when it is curated enough to discuss and tied to an
active issue. Each review batch must include a manifest based on
`docs/templates/asset-batch-manifest.md`.

Approved assets move out of `_review` and into the appropriate game asset
folder. Rejected batches may be removed in a cleanup commit. Keep `.blend`
source files in review or source-art folders; do not place them in runtime
asset folders unless the project Blender path is intentionally configured.

## LFS

Binary assets and source art are tracked with Git LFS through `.gitattributes`.
Godot import caches such as `.godot/` and `.import/` stay ignored.

## Review Batch Naming

Use issue-based folder names:

```text
assets/_review/generated/issue-41-starter-asset-batch/
assets/_review/vendor/issue-44-low-poly-fishing-pack/
```

Keep names descriptive enough that a future contributor can understand the
batch without opening every file.
