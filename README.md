# One More Cast

One More Cast is the standalone game repository.

The reusable 3D pipeline lives in this repo as a Git submodule at
`tools/3DCodexPipeline`.

See [docs/repository-setup.md](docs/repository-setup.md) for the repo layout,
submodule workflow, and rules for where game code and reusable pipeline code
belong.

## First Playable

The current prototype is a minimal Godot project with a one-button casting loop.
Open the repo in Godot and run `scenes/main.tscn`.

The loop moves through `ready`, `casting`, `waiting`, `bite`, `reeling`, and
`result`, then records the latest catch or empty cast in a simple in-memory
inventory and journal.
