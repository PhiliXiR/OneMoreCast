# Fishing Mechanics Bible

This document defines how fishing should work in One More Cast. It is a design
canon document, not a task list. It should help future code, assets, animation,
UI, and tuning decisions keep the fishing loop coherent.

The current prototype is allowed to take shortcuts, but those shortcuts should
not collapse the underlying fishing model into one object doing every job.

## North Star

One More Cast should use real-world fishing logic with prototype-friendly
implementation.

The player should understand the loop through familiar fishing concepts:
standing near water, aiming, casting, lure landing, line settling, waiting for a
bite, setting the hook, reeling in, landing a fish, and recording the catch.

The game does not need full simulation accuracy at first. It can fake line
physics, fish presence, lure motion, water interaction, and reel-in motion as
long as the player's mental model matches real fishing.

The guiding rule is:

```text
Believable object responsibilities matter more than perfect physics.
```

If the player sees a line, lure, hook, fish, or bobber, that object should behave
roughly like its real-world role.

## Current Prototype

The current prototype is a lure-first dock fishing loop.

The current playable loop is:

```text
Ready -> Casting -> Waiting -> Bite -> Reeling -> Result -> Ready
```

The player stands near water, aims with a target marker, casts a placeholder
lure, waits for a bite, presses the hook-set action during the bite window, then
watches an automatic reel-in before receiving a fish result.

Current implementation facts:

- The main rig is a lure-first rig.
- Fish are abstract before the bite.
- A hooked fish marker is spawned only after a successful hook-set.
- Reeling is automatic.
- Hook-set success is a simple timing-window check.
- The line is rendered as a projected `Line2D` using world-space line points.
- The line now follows an explicit invisible `LineEndpoint`.
- The target marker is an aim assist, not a physical fishing object.
- The visible lure and hook are separate placeholder markers driven by the line
  endpoint.
- The fish is still placeholder geometry.
- The result is currently a named `Dock Bluegill`.

Current prototype shortcuts:

- `BITE` currently covers both bite signal and hook-set window.
- `REELING` is a timed automatic visual beat, not an interactive tension system.
- Fish behavior is probability/state driven, not actor driven.
- The line does not have true physical collision, weight, or water drag.
- Landing quality is a simplified value derived from cast location.
- Inventory and journal updates are simple text feedback.

These shortcuts are acceptable while the prototype is proving the loop. They are
not the target model.

## Target Model

The target model separates real fishing concepts into distinct objects and
states. The code may compress states during early prototyping, but it should not
collapse object responsibilities.

The target fishing loop is:

```text
Ready
  -> Aiming
  -> Casting
  -> Landed
  -> Settling
  -> WaitingForBite
  -> BiteSignal
  -> HookSetWindow
  -> Hooked
  -> Reeling
  -> LandedFish
  -> Result
  -> Ready
```

This more detailed state machine is the design reference. Prototype code can
combine adjacent states only when the player-facing behavior remains clear.

## Glossary

### Rig

The player's current fishing setup. A rig defines what is attached to the rod and
line and therefore what loop is being played.

Examples:

- Lure rig
- Bobber rig
- Bait rig

The current prototype uses a lure rig.

### Rod

The player-held tool used to aim, cast, set the hook, and transmit tension.

The rod is responsible for:

- Ready pose
- Cast swing
- Hook-set motion
- Bend/pulse/tension feedback
- Directional relationship to the line

The rod should not own fish logic or catch resolution.

### Reel

The mechanism used to retrieve line.

In the current prototype, reel-in is automatic. In the target model, the reel
becomes an interactive system that controls line retrieval, tension, and fish
fight pacing.

### Line

The visual and logical connection from the rod tip to the line endpoint.

The line is responsible for:

- Cast arc feedback
- Slack after landing
- Tautness during bite and reel-in
- Tension communication
- Shortening during reeling

The line should attach to a line endpoint, not directly to whatever placeholder
visual happens to be visible.

### Line Endpoint

An invisible logic point at the end of the line.

This is one of the most important concepts in the model. The line endpoint is
not necessarily the visible lure, hook, bobber, or fish. It is the simulation
anchor that other visuals attach to or follow.

The line endpoint is responsible for:

- Being the end of the line
- Moving during cast
- Landing in or out of water
- Driving line rendering
- Acting as the attachment reference for terminal tackle

The line endpoint may be invisible.

### Terminal Tackle

The objects at the end of the line.

Terminal tackle can include:

- Hook
- Lure
- Bobber
- Sinker
- Bait

In the current lure prototype, the terminal tackle is essentially a visible lure
and hook placeholder attached to the line endpoint.

### Hook

The part that can attach to a fish.

The hook is responsible for:

- Being the attachment point when a hook-set succeeds
- Moving with the lure or bait
- Becoming linked to the hooked fish after success
- Staying embedded in the hooked fish through reel-in until the fish reaches
  the rod/landing point
- Remaining underwater with the hooked fish until the catch resolves

The hook should not be the same conceptual object as the bobber, fish, or line
endpoint.

### Lure

A visible artificial bait attached to the hook. The lure is what the player casts
and what the fish responds to in a lure rig.

The lure is responsible for:

- Being visible in the world
- Landing near the line endpoint
- Twitching or moving during bite feedback
- Communicating lure presence to the player

In the current prototype, the yellow ball is standing in for the lure/hook. It
should eventually become a small lure or hook-like object, not a bobber.

### Bobber

An optional floating bite indicator used by bobber rigs.

The bobber is not part of the current lure-first prototype. It belongs to a
future rig type with a different read:

```text
cast -> bobber floats -> bobber dips/twitches -> set hook
```

A bobber should not be used as the default visual for lure fishing unless the
selected rig actually includes one.

### Fish Presence

Pre-hook fish presence is abstract for now. The game may evaluate a cast using
water zone, landing quality, fish table, lure behavior, time, and probability
without showing actual fish.

Fish presence is responsible for:

- Determining whether a bite can happen
- Biasing bite timing and catch chance
- Representing fish interest before the fish is visible

The current prototype does not require visible fish before bite.

### Hooked Fish

A visible fish actor spawned or revealed after a successful hook-set.

The hooked fish is responsible for:

- Appearing underwater near the hook/line endpoint
- Remaining underwater early in reel-in
- Moving closer to the rod as line is retrieved
- Becoming readable to the player as it nears the landing moment

The hooked fish should not pop immediately above the surface when hooked. It
should stay underwater until the reel-in has brought it close enough to plausibly
surface or be landed.

### Catch

The final landed result that can update inventory, journal, progression, or
collection systems.

A catch is not the same as a hooked fish. A fish can be hooked and then lost.
A caught fish is a completed result.

## Rig Types

### Lure Rig

The lure rig is the current prototype rig and the first real gameplay target.

Lure rig loop:

```text
aim -> cast lure -> lure lands -> line settles -> wait -> bite/twitch -> set hook -> reel -> catch or lose
```

The player reads the lure rig through:

- Lure landing
- Line settling
- Lure/line/rod twitch
- Reel-in motion
- Fish appearing underwater after hook-set

### Bobber Rig

Bobber rigs are future work.

Bobber rig loop:

```text
aim -> cast bobber/bait -> bobber floats -> fish bites -> bobber dips -> set hook -> reel -> catch or lose
```

The player reads the bobber rig primarily through bobber movement, not lure
twitch.

### Bait Rig

Bait rigs are future work.

Bait rig loop:

```text
aim -> cast bait/hook -> bait settles -> wait -> subtle bite signal -> set hook -> reel -> catch or lose
```

Bait rigs may use a bobber, bottom rig, sinker, or other tackle depending on
future design.

## State Machine

### Ready

The player is not currently casting or fishing.

Expected behavior:

- Rod is in ready pose.
- Line endpoint is near the rod/hook rest point.
- No fish is attached.
- Cast input is available if the player is near fishable water.

### Aiming

The player previews where the cast will land.

Expected behavior:

- Target marker shows a projected landing point.
- Marker is valid or invalid based on fishing rules.
- Marker should be subtle and clean, not a giant beacon.
- Line remains near the rod and should not stretch all the way to the target.

### Casting

The player sends the terminal tackle through the air.

Expected behavior:

- Rod swings.
- Line unrolls.
- Line endpoint travels toward the target.
- Visible lure/hook follows the line endpoint.
- Fish are not visible yet.

### Landed

The line endpoint reaches the cast destination.

Expected behavior:

- Water landing produces splash/ripple.
- Non-water landing produces miss feedback.
- Landing quality is recorded.
- The system knows whether the cast is fishable.

### Settling

The line and lure settle after landing.

Expected behavior:

- Line can be slack briefly.
- Lure sits in/near the water.
- Landing feedback finishes.
- The system prepares to enter waiting if the cast is valid.

### WaitingForBite

The lure/hook is fishable and the game is waiting for fish interaction.

Expected behavior:

- Fish presence may be abstract.
- The player sees a calm line/lure/rod state.
- Waiting duration can depend on landing quality, fish presence, lure type, time
  of day, weather, and future systems.

### BiteSignal

A fish interacts with the lure/hook.

Expected behavior:

- The player sees in-world feedback before or alongside HUD feedback.
- Lure, line, and rod may twitch.
- A bobber rig would show bobber movement instead.
- The fish is still not necessarily visible.

### HookSetWindow

The player has a short chance to convert the bite into a hooked fish.

Current prototype rule:

```text
If the player presses hook-set during the bite window, attach fish.
```

Future target rule:

Hook-set success may depend on timing, fish species, bite strength, lure type,
hook size, rod angle, line slack, line tension, and player reaction.

### Hooked

The fish is now physically attached to the hook/line system.

Expected behavior:

- Hooked fish actor appears or becomes active underwater.
- Fish starts below the surface.
- Line becomes connected to the hooked fish through the hook/line endpoint.
- Hook remains in the fish as it is reeled toward the rod.
- The line endpoint stays underwater at the hook/fish mouth point until the
  catch resolves.
- The player should understand that the fish is attached, not already caught.

### Reeling

The fish is brought closer by retrieving line.

Current prototype:

- Reeling is automatic.
- The line shortens.
- The fish marker moves closer to the rod.
- The fish stays underwater until it is close.
- Rod and line provide tension-like visual feedback.

Future target:

- Reeling becomes interactive.
- Player input controls retrieval.
- Fish can pull away.
- Tension can rise and fall.
- Too much tension can break the line or lose the fish.
- Too little tension can allow escape.
- Rod angle, drag, fish stamina, and line type can matter.

### LandedFish

The fish is close enough to be landed.

Expected behavior:

- Fish becomes clearly visible.
- Fish may break the surface or be lifted.
- The line endpoint, hook, and fish resolve into a landed presentation.

### Result

The fishing attempt resolves.

Possible results:

- Caught fish
- Missed bite
- Lost fish during reel
- Invalid cast
- Empty water
- Snag or junk item in future systems

Result should update the appropriate systems: HUD, journal, inventory,
collection, progression, or save data.

## Object Responsibility Rules

These rules are more important than the current implementation details.

- Do not use one visible object as lure, hook, bobber, fish, and line endpoint.
- The line endpoint may be invisible.
- The line should render to the line endpoint.
- Visible lure/hook/bobber/fish objects should be attached to or driven by the
  line endpoint depending on state.
- The bobber belongs to bobber rigs, not the default lure prototype.
- Fish are abstract before hook-set in the current prototype.
- Hooked fish may be spawned as a temporary actor after hook-set.
- Hooked fish should remain underwater early in reel-in.
- During reel-in, the hook should remain visually embedded in the hooked fish
  until the fish reaches the rod/landing point.
- The line should run from the rod tip to the underwater hook/fish point during
  reel-in, not to a floating lure marker or above-water placeholder.
- Reeling must be modeled as a distinct state, even while automatic.
- Catch result should happen after reel/landing, not immediately on hook-set.
- HUD text should reinforce physical feedback, not replace it.

## Implementation Rules

The code can be prototype-friendly, but it should preserve the model.

### Allowed Prototype Shortcuts

- Fish presence can be probability/state based before hook-set.
- The line can be a visual approximation rather than a physical rope.
- Reeling can be automatic.
- Hook-set can use a simple timing window.
- Lure, hook, and fish can use placeholder meshes.
- State names in code can be compressed when the design state remains clear.

### Forbidden Shortcuts

- Do not make the target marker a physical fishing object.
- Do not treat a bobber as the lure unless the selected rig is a bobber rig.
- Do not make the fish appear as already caught immediately after hook-set.
- Do not skip the reeling phase after a successful hook-set.
- Do not let the line stay fully extended during reel-in.
- Do not make text the only indication of bite, hook-set, reel, or catch.

## Current Prototype Mapping

The current prototype maps the design model as follows:

```text
Design State       Current Prototype
------------       -----------------
Ready              READY
Aiming             implicit while READY
Casting            CASTING
Landed             handled inside spatial casting
Settling           handled inside spatial casting
WaitingForBite     WAITING
BiteSignal         BITE
HookSetWindow      BITE
Hooked             hook_set flag + hooked fish marker
Reeling            REELING
LandedFish         compressed into RESULT
Result             RESULT
```

This mapping is acceptable for the current prototype, but future work should
split states when mechanics need clearer timing, animation, or interaction.

## Current Visual Object Mapping

```text
Design Object      Current Prototype
-------------      -----------------
Line endpoint      LineEndpoint invisible Node3D
Lure               LureMarker placeholder
Hook               HookMarker placeholder
Bobber             not present
Fish presence      abstract
Hooked fish        HookedFishMarker placeholder
Fish mouth         HookedFishMouthMarker at the underwater line endpoint
Target marker      CastTargetMarker reticle
Line               FishingLineOverlay Line2D
Rod                PlayerRig RodRoot/RodTip
```

The visible `LureMarker` and `HookMarker` are still placeholder meshes, but they
are now driven by the invisible `LineEndpoint` instead of serving as the line's
simulation anchor.

During reel-in, `HookedFishMouthMarker`, `HookMarker`, and `LineEndpoint` should
stay together underwater so the line reads as connected to the fish's mouth.

## Design Priorities

When two possible implementations conflict, prefer the one that:

1. Preserves object responsibilities.
2. Makes the physical fishing sequence readable.
3. Keeps the current prototype playable.
4. Allows future rig types.
5. Avoids overbuilding simulation too early.

## Open Questions

These are intentionally unresolved.

- How many rig types should be available in the first vertical slice beyond the
  lure rig?
- Should lure retrieval eventually matter before a bite?
- How visible should fish be in clear water before hook-set?
- What is the first real fish model and animation style?
- When should reeling become interactive?
- Should line tension be a HUD meter, physical rod/line feedback, or both?
- How should weather, water depth, time, and location affect fish presence?
- How should landing quality interact with species and rarity?

## Summary

One More Cast should feel like fishing before it becomes a detailed fishing
simulation.

The first prototype target is not perfect physics. It is a believable sequence
of distinct responsibilities:

```text
rod casts -> line follows endpoint -> lure/hook lands -> fish bites -> player
sets hook -> hooked fish appears underwater -> line shortens -> fish is landed
-> catch is recorded
```

Every future system should protect that mental model.
