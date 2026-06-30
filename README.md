# One More Cast

One More Cast is the standalone game repository.

The reusable 3D pipeline lives in this repo as a Git submodule at
`tools/3DCodexPipeline`.

See [docs/repository-setup.md](docs/repository-setup.md) for the repo layout,
submodule workflow, and rules for where game code and reusable pipeline code
belong.

## First Playable

The current prototype includes a minimal one-button casting loop.
Open the repo in Godot and run `scenes/main.tscn` to test it by itself.

The loop moves through `ready`, `casting`, `waiting`, `bite`, `reeling`, and
`result`, then records the latest catch or empty cast in a simple in-memory
inventory and journal.

## 3D Prototype

The default run scene is `scenes/world_prototype.tscn`. It combines a game-owned
player wrapper, reusable movement and camera scripts from the `3DCodexPipeline`
submodule, and the current casting UI.

See [docs/pipeline-runtime-integration.md](docs/pipeline-runtime-integration.md)
for the runtime integration boundary between OneMoreCast and the reusable
pipeline.
