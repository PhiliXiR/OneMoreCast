# Interactive Reeling Plan

## Goal

Turn the automatic reel-in into a short, readable `reel or yield` fish fight.
A competent player should land the prototype Dock Bluegill in roughly 12–18
seconds by reeling during recovery phases and yielding during telegraphed
surges.

## Player Experience

The existing contextual fishing action casts, sets the hook, and reels while
held. During a fish fight:

- Reeling during recovery advances landing progress while tension remains safe.
- Yielding during recovery lowers tension toward slack.
- Reeling during a surge rapidly raises tension.
- Yielding during a surge returns tension toward safety while the fish regains
  modest distance.
- Sustained excessive tension breaks the line.
- Sustained slack lets the fish throw the hook.
- Both failure modes use a short danger window, so one mistake is recoverable.
- Landing progress reaching its threshold enters a distinct landed-fish
  presentation before the catch result is recorded.

The Dock Bluegill uses two or three lightly randomized surges. Its first surge
has a longer wind-up, and a fight never begins with an immediate surge. Surge
progress loss is capped by per-surge progress floors so the fight cannot fully
reset.

## Scope

### Included

- Hold-to-reel and release-to-yield through the existing `set_hook` action and
  action button.
- Recovery, surge wind-up, and surge fish-fight phases within `REELING`.
- Tension, landing progress, high-tension danger, and slack danger.
- Line-break and thrown-hook results with corrective messages.
- A `LANDED_FISH` cast state and brief catch presentation.
- A compact gauge showing slack, safe, and high-tension regions.
- Fish, rod, line, gauge, and lightweight audio feedback for surge and danger.
- Three first-fight tutorial messages, shown once per play session.
- Journal entries for catches and both loss causes.

### Excluded

- Fish stamina, directional rod control, drag adjustment, tackle durability, or
  consumed lures.
- Production fish art, final animation, final sound design, or HUD skinning.
- Saved tutorial completion.
- Species-specific fight data beyond the prototype Dock Bluegill tuning.

## Design Shape

`REELING` remains the cast-level state for the whole fight. Recovery, surge
wind-up, and surge are internal fish-fight phases. `LANDED_FISH` is added between
`REELING` and `RESULT`; failures transition directly from `REELING` to `RESULT`.

Create one game-owned fight model as the authority for phase timing, tension,
landing progress, danger accumulation, and outcome. The casting controller
orchestrates the cast lifecycle and contextual input. The spatial casting
controller presents model output through fish, hook, line, and rod motion. The
HUD observes the same model output and never calculates fight outcomes.

The model should accept explicit delta and reel-held input and expose a small
snapshot suitable for deterministic scripted validation. Random phase durations
should be selected when a fight begins, not sampled continuously.

## Implementation Sequence

### 1. Time-box validation diagnosis

- Reproduce the Godot 4.7 crash with the project validators and a blank project.
- Check whether normal editor play is affected.
- Record the result in `docs/development-environment.md`.
- If the crash is environment-wide, continue with manual editor validation
  rather than blocking the feature.

Exit condition: the team knows which validation route is usable for this slice.

### 2. Add the deterministic fight model

- Add recovery, surge wind-up, and surge phases.
- Track normalized tension, landing progress, high-tension danger, slack danger,
  current phase, phase time, surge count, and terminal outcome.
- Implement the agreed phase/input matrix and smooth tension movement.
- Add modest surge line loss with a progress floor captured at each surge.
- Tune the Dock Bluegill toward a 12–18 second successful fight with two or
  three surges.

Exit condition: scripted delta/input sequences deterministically produce an
ongoing fight, landed fish, line break, and thrown hook.

### 3. Replace timed automatic reeling with contextual hold input

- Reuse `set_hook`; do not add a dedicated reel action.
- Treat both keyboard and pointer button press/release as held input.
- Change the action button to `Hold to Reel` while fighting and show its held
  state.
- Drive the fight model only while the cast controller is in `REELING`.
- Route terminal outcomes to `LANDED_FISH` or `RESULT` as appropriate.

Exit condition: keyboard and on-screen controls have identical reel/yield
semantics, including immediate yield on release.

### 4. Drive the existing spatial presentation from fight state

- Replace elapsed-time reel progress with model landing progress.
- Keep the hook embedded at the fish mouth and the line endpoint underwater
  until landing.
- Add an unmistakable surge wind-up, stronger surge motion, rod loading, and
  line response using current placeholder geometry.
- Let a surging fish move away only by the model's capped amount.

Exit condition: recovery, wind-up, surge, yield, and danger are readable in the
world without relying exclusively on text.

### 5. Add the tension HUD and first-fight teaching

- Add one horizontal gauge with slack, safe, and high-tension regions.
- Pulse the relevant edge while its danger window accumulates.
- Avoid numeric tension and countdown displays.
- Show the three agreed contextual tutorial messages once per play session:
  hold during recovery, release at the first surge, and a cause-specific first
  danger warning.
- Add a lightweight surge audio cue or a clearly marked temporary substitute.

Exit condition: a first-time player can explain why they should hold or release
and why a fish was lost.

### 6. Add landing and loss resolution

- Add `LANDED_FISH` to the cast state machine and state labels.
- Present the fish briefly at the surface or rod before recording the catch.
- Record inventory only after the landed presentation.
- Record line break and thrown hook separately in the journal with no inventory,
  tackle, currency, durability, or progression penalty.
- Return all outcomes promptly to `READY`.

Exit condition: success, missed hook-set, line break, and thrown hook are
visually and textually distinct outcomes.

### 7. Validate and tune the complete loop

- Extend `validate_3d_prototype.gd` with deterministic recovery/surge, input,
  progress-floor, grace-window, landing, and both failure scenarios.
- Preserve existing line endpoint, underwater hook, fish-mouth attachment, HUD
  input, and menu integration assertions.
- Manually play keyboard and pointer paths at multiple window sizes.
- Manually complete at least one catch, line break, and thrown hook.
- Tune for the target duration and verify that one mistake is recoverable.
- Update the current-prototype section of the fishing mechanics bible only after
  the implementation matches it.

Exit condition: all usable automated checks pass, manual outcome paths pass,
and the documented prototype behavior matches the game.

## Acceptance Criteria

- A competent Dock Bluegill fight usually lasts 12–18 seconds and contains two
  or three readable surges.
- Holding the contextual action reels; releasing yields on both keyboard and
  the on-screen button.
- Recovery and surge reward the agreed opposite inputs.
- A surge is telegraphed before dangerous tension gain begins.
- A surging fish regains limited distance without resetting the whole fight.
- One brief tension or slack mistake is recoverable.
- Sustained high tension causes a line break; sustained slack causes a thrown
  hook.
- The HUD distinguishes slack, safe tension, high tension, and accumulating
  danger without requiring numeric readouts.
- A successfully retrieved fish enters `LANDED_FISH` before inventory and
  journal catch updates.
- Losses create distinct journal entries, consume nothing, and allow another
  cast immediately.
- Existing fishing-line attachment and underwater hooked-fish behavior remain
  intact.
- The feature remains game-owned and introduces no fishing assumptions into
  `3DCodexPipeline`.
