# Water and Fish Presence Plan

## Goal

Make the prototype lake feel alive and physically connected to the fishing
loop, then replace the hooked-fish placeholder with an identifiable, animated
Dock Bluegill.

The result should preserve mystery before hook-set: the player sees indirect
fish signs, not freely swimming fish actors. After hook-set, the fish becomes a
readable physical presence throughout the fight and landing.

## Visual Direction

### Water

Use a game-owned lake shader compatible with Godot's Compatibility renderer.
The lake should have:

- continuous gentle surface motion from layered scrolling detail;
- view-angle colouring and highlights;
- shallow-to-deep blue-green colour and opacity;
- enough underwater readability to show a hooked-fish silhouette;
- no dependency on an ocean framework or Forward+-only reflections.

The water should be moderately clear near the dock and active tackle. A hooked
fish reads first as a silhouette at depth, then gains colour and detail as it
approaches and rises.

### Dock Bluegill

The Dock Bluegill establishes a stylized-naturalistic fish language:

- recognizable bluegill anatomy and markings;
- slightly exaggerated body depth and fins for gameplay-camera readability;
- clean low-to-mid-poly geometry;
- hand-painted colour blocks rather than photoreal scales;
- a reusable rig and material structure suitable for later small-bodied fish.

## Player-Facing Water Language

Water reactions form one coherent effect family with event-specific position,
scale, intensity, and timing:

| Event | Read |
| --- | --- |
| Ambient fish sign | Occasional shadow, wake, or disturbance that makes the lake feel inhabited; promises nothing. |
| Cast entry | Small splash followed by expanding ripples. |
| Waiting lure | Gentle wake or pulse that maintains tackle presence. |
| Lure-focused fish sign | Activity near the cast that implies growing interest without guaranteeing a bite. |
| Bite signal | Strong, unmistakable disturbance distinct from incidental fish signs. |
| Hooked-fish surge | Directional wake and occasional stronger splash tied to resistance. |
| Landing | The strongest localized splash, resolving into settling ripples. |

## Runtime Boundary

Create a reusable, game-owned `WaterSurface` scene. It owns the lake material
and the presentation of ripples, wakes, and splashes. Fishing systems request
semantic reactions such as cast entry, fish sign, bite, surge, and landing;
they do not manipulate shader details directly.

Keep fish presence state-driven in this slice. Do not add free-swimming fish
actors, spawning, schooling, habitat navigation, or underwater collision. The
Dock Bluegill becomes visible after hook-set. Its calm swimming motion supports
the hooked-fish recovery phase now and can support free-swimming actors later.

## Fish Asset Contract

The Dock Bluegill asset package must contain:

- an editable Blender source file;
- a Godot-ready GLB with mesh, skeleton, material, and animation clips;
- a compact texture set;
- a calm swimming animation;
- a struggle/surge animation;
- a short landed presentation;
- a preview scene that exposes all three motions;
- a review screenshot and asset-batch manifest.

The candidate begins under `assets/_review/generated/` in an issue-named batch.
After approval, promote the runtime GLB and textures into `assets/fish/`. Keep
editable source art in the review or source-art location defined by the asset
intake workflow.

## Delivery Slices

### 1. Lake Surface

- Extract the prototype water into `WaterSurface`.
- Build and tune the Compatibility-renderer lake shader.
- Preserve the existing fishable-water rules and casting geometry.
- Establish stable semantic entry points for localized reactions.

### 2. Water Reactions and Fish Signs

- Implement the full water-reaction language.
- Drive reactions from the existing fishing states and fight phases.
- Keep ambient signs, lure-focused signs, and the bite signal distinguishable.
- Ensure effects reinforce rather than obscure the lure, line, and tension cues.

### 3. Dock Bluegill

- Create and review the source model, rig, materials, and animations.
- Promote the approved runtime asset.
- Replace `HookedFishMarker` placeholder geometry without changing hook, mouth,
  line-endpoint, or underwater-fight responsibilities.
- Use calm swimming, surge, and landed motions in their corresponding phases.

## Quality Gate

During one complete cast-and-catch sequence:

- the lake shows continuous gentle motion, depth colouring, and readable
  highlights without obvious repetition;
- important water contacts produce correctly positioned and scaled reactions;
- ambient signs, lure-focused signs, and the bite signal are distinguishable;
- the hooked bluegill remains readable underwater and becomes clearer near
  landing;
- its silhouette and three motions read from the normal gameplay camera;
- effects remain smooth with the Compatibility renderer;
- effects do not obscure line, lure, hook, or line-tension feedback;
- a before/after screenshot and short gameplay capture receive review.

Existing prototype validation must continue to pass. New validation should
cover semantic water-reaction requests and preserve the established underwater
hook, fish-mouth, and line-endpoint relationship.

## Explicitly Out of Scope

- Forward+ as a renderer requirement;
- screen-space-reflection-dependent water;
- an infinite-ocean or general fluid-simulation framework;
- free-swimming fish actors and fish AI;
- schooling, habitat simulation, and underwater navigation;
- additional authored fish species;
- changing the fishing state model or fish-fight rules.
