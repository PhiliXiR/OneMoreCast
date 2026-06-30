# Repository Setup

One More Cast is a standalone game repository that uses
`3DCodexPipeline` as a reusable toolchain dependency.

The pipeline is included as a Git submodule. It is not copied into this repo,
and the two repositories should stay separate.

## Layout

```text
Projects/
├── 3DCodexPipeline/          # existing reusable pipeline repo
└── OneMoreCast/              # standalone game repo
    └── tools/
        └── 3DCodexPipeline/  # submodule reference to existing repo
```

Inside `OneMoreCast`, game-specific work belongs in the game folders:

```text
assets/
audio/
docs/
scenes/
scripts/
ui/
fish/
lures/
crafting/
inventory/
journal/
player/
boat/
world/
weather/
save/
```

Reusable pipeline work belongs in:

```text
tools/3DCodexPipeline/
```

## Mental Model

`OneMoreCast` owns the game.

`3DCodexPipeline` owns the reusable toolchain.

The game repo records one exact pipeline commit through the submodule pointer.
When you commit `OneMoreCast`, Git does not commit all of the pipeline files.
It commits a reference that says which pipeline version the game uses.

## Cloning

Clone with submodules:

```powershell
git clone --recurse-submodules https://github.com/PhiliXiR/OneMoreCast.git
```

If the repo was cloned without submodules, initialize them afterward:

```powershell
git submodule update --init --recursive
```

## Working On Game Code

For game-specific changes, work from the game repo:

```powershell
cd C:\_Dev\OneMoreCast
```

Then use the normal Git workflow:

```powershell
git add .
git commit -m "Add fishing prototype scene"
git push
```

Do not put game-specific code in `tools/3DCodexPipeline`.

## Updating The Pipeline Version

When `3DCodexPipeline` has newer changes and the game should use them:

```powershell
cd C:\_Dev\OneMoreCast\tools\3DCodexPipeline
git pull origin main

cd C:\_Dev\OneMoreCast
git add tools/3DCodexPipeline
git commit -m "Update 3DCodexPipeline submodule"
git push
```

The second commit updates the game repo's pointer to the newer pipeline commit.

## Improving Reusable Pipeline Tools

If you improve reusable pipeline tooling while working inside `OneMoreCast`,
commit and push those changes from the submodule first:

```powershell
cd C:\_Dev\OneMoreCast\tools\3DCodexPipeline

git add .
git commit -m "Improve reusable pipeline tooling"
git push origin main
```

Then update the game repo's submodule pointer:

```powershell
cd C:\_Dev\OneMoreCast

git add tools/3DCodexPipeline
git commit -m "Update pipeline submodule reference"
git push
```

This two-step workflow keeps reusable pipeline history in the pipeline repo and
game history in the game repo.

## Rule Of Thumb

If it only makes sense for One More Cast, it belongs in `OneMoreCast`.

If it could help future 3D or game projects too, it belongs in
`3DCodexPipeline`.

Game-specific code stays in `OneMoreCast`.

Reusable pipeline code stays in `3DCodexPipeline`.
