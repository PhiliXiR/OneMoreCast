# Spatial Casting Prototype

The first spatial casting pass turns casting from a global button roll into a
world-aware action.

## Prototype Rules

- The player must stand near the fishable water rectangle.
- The cast target is projected from the player in the current camera-facing
  direction.
- A visible target marker previews where the lure would land.
- Targets inside the fishable water rectangle are valid.
- Targets outside the water are invalid and block casting.
- Valid casts animate a placeholder lure from the player to the target point.
- Landing quality is based on how close the lure lands to the water's current
  sweet spot.
- Landing quality biases the placeholder catch chance.

## Current Scope

This is still prototype fishing. It does not include lure selection, line
tension, fish habitats, reeling skill checks, final VFX, animation, or save
progression.

The goal is to prove the core spatial rhythm:

```text
stand near water -> aim -> preview target -> cast -> lure lands -> result
```
