# Pipeline Runtime Integration

OneMoreCast consumes reusable Godot runtime systems from `3DCodexPipeline`
through composition.

The game repo owns game-specific wrapper scenes, game input context, fishing
state, angler identity, level composition, UI, inventory, journal, and save
behavior. The pipeline repo owns reusable movement, camera, controls, tooling,
and validation systems.

## Wrapper Scene Rule

Use game-owned wrapper scenes when bringing pipeline runtime systems into
OneMoreCast.

For example, `player/PlayerRig.tscn` belongs to OneMoreCast. It can attach the
pipeline movement controller script and use the pipeline camera output contract,
but it is still the game's player assembly point.

This keeps the boundary clear:

```text
OneMoreCast/player/PlayerRig.tscn
  owns game-specific player composition and future fishing hooks

tools/3DCodexPipeline/game/systems/character/
  owns reusable movement controller behavior

tools/3DCodexPipeline/game/systems/camera/
  owns reusable camera behavior
```

## When To Change OneMoreCast

Change OneMoreCast when the work is specific to this game:

- Angler identity.
- Fishing input and casting rules.
- Inventory, journal, save, and progression.
- World, boat, water, weather, fish, lures, and UI composition.
- Scene wrappers that assemble reusable systems into the game.

## When To Change 3DCodexPipeline

Change 3DCodexPipeline when the work improves reusable infrastructure:

- Movement controller behavior that should help future games.
- Camera orbit, zoom, collision, and mode output behavior.
- Controls feel helpers.
- Validation scripts for reusable systems.
- Pathing or packaging changes that make the systems easier to consume as a
  submodule.

If a pipeline change is made from inside OneMoreCast, commit and push it inside
the submodule first, then commit the updated submodule pointer in OneMoreCast.

## Current Integration

The 3D prototype uses a game-owned scene and player wrapper:

```text
scenes/world_prototype.tscn
player/PlayerRig.tscn
```

The wrapper attaches reusable scripts from:

```text
tools/3DCodexPipeline/game/systems/character/scripts/
tools/3DCodexPipeline/game/systems/camera/scripts/
```

The existing casting UI remains game-owned and is instanced into the 3D
prototype so movement, camera, and fishing feedback can be tested together.
