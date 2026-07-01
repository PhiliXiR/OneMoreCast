# ADR 0001: OneMoreCast and 3DCodexPipeline Boundary

## Status

Accepted

## Context

OneMoreCast is a standalone fishing game. It consumes `3DCodexPipeline` as a
submodule at `tools/3DCodexPipeline`.

The pipeline is intended to become a reusable AI-assisted game development
foundation. OneMoreCast is the first game proving which systems, tools, and
workflows are actually reusable.

We need a clear boundary so the game can move quickly without turning the
pipeline into a collection of premature abstractions.

## Decision

OneMoreCast owns game-specific implementation, tuning, authored content, and
feel.

3DCodexPipeline owns stable generic runtime systems and reusable production
tools.

Stable generic runtime systems are consumed through the submodule. Generated
content and one-off scaffolding are copied into OneMoreCast and become
game-owned.

Systems that might become reusable should start in OneMoreCast by default. They
are promoted to 3DCodexPipeline only after real gameplay proves the shape.

Breaking changes are allowed while both projects are early, but every promotion
must include the OneMoreCast migration and validation in the same work slice.

## OneMoreCast Owns

- Fishing-specific casting feel.
- Rod motion tuning.
- Fishing line slack, tension, and reeling behavior.
- Hook, lure, bait, and bite rules.
- Fish species, habitats, and AI.
- Lake, river, ocean, dock, boat, quest, story, economy, and progression content.
- Game HUD content, copy, and art direction.
- Generated scenes, generated assets, and one-off scaffolding after they are
  imported into the game.

## Pipeline Runtime Dependencies

OneMoreCast may reference stable generic runtime systems directly from the
submodule, such as:

- Camera controllers.
- Character movement controllers.
- Input abstractions.
- Generic interaction systems.
- Generic save/load frameworks.
- Generic inventory frameworks.
- Generic debug overlays.
- Generic validation hooks.

These remain pipeline-owned and should not be copied into the game unless there
is a deliberate fork.

## Generated Output

Pipeline-generated output becomes game-owned once imported into OneMoreCast.

Examples include:

- Generated docks.
- Lake layouts.
- Shoreline meshes.
- Fishing spot scenes.
- World dressing.
- Scene scaffolds.
- Game-specific data files.

The pipeline tool should remain reproducible, but the generated output is not
sacred. OneMoreCast may hand-edit it freely.

## Promotion Rule

Promotion path:

```text
OneMoreCast local prototype
  -> proven through gameplay
  -> remove fishing/game assumptions
  -> move reusable core to 3DCodexPipeline
  -> migrate OneMoreCast to consume the pipeline version
  -> validate OneMoreCast in the same slice
```

A system is ready to promote only when:

- The game-specific names and assumptions have fallen away.
- The API makes sense without OneMoreCast context.
- Another game could consume it without inheriting fishing rules.
- OneMoreCast can migrate to it immediately.

## Consequences

This favors game progress over speculative reuse.

Some code will begin in OneMoreCast and later move. That is acceptable. The
pipeline should grow from proven gameplay pressure, not from guesses about what
might be useful someday.
