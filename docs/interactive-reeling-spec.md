# Interactive Reel-or-Yield Fish Fight

## Problem Statement

Hooking a fish currently triggers a short automatic reel-in. The player makes a
decision when casting and setting the hook, but the central fish-fight beat plays
itself. The hooked fish cannot meaningfully resist, line tension cannot create
risk, and success arrives without the player reading or responding to the fish.
This makes the prototype mechanically complete but emotionally flat at the most
important moment of the fishing loop.

## Solution

Replace automatic reel-in with a short, readable reel-or-yield fight for the
Dock Bluegill. The existing contextual fishing action reels while held and
yields when released. The player reels during recovery, responds to a
telegraphed surge by yielding, and manages line tension inside a safe range while
making landing progress.

A surging fish may regain limited distance, but cannot reset the whole fight.
Sustained excessive line tension causes a line break; sustained line slack lets
the fish throw the hook. Both outcomes use a danger window so a single mistake
is recoverable. A successful fight enters a distinct landed-fish presentation
before recording the catch.

The interaction is taught through world feedback, a compact line-tension gauge,
lightweight audio, and three non-modal first-fight messages. A competent player
should usually land the Dock Bluegill in 12–18 seconds through two or three
readable surges.

## User Stories

1. As a player who has set the hook, I want to control retrieval, so that landing the fish depends on my decisions.
2. As a player, I want to hold the existing contextual fishing action to reel, so that I do not need to learn a second fishing control.
3. As a player, I want releasing the action to yield immediately, so that I can respond precisely to a fish surge.
4. As a keyboard player, I want the contextual key to support hold and release, so that the fight feels responsive.
5. As a pointer user, I want the on-screen action button to support the same hold and release behavior, so that both control paths are equivalent.
6. As a player, I want the action button to read `Hold to Reel` during a fight, so that its current purpose is clear.
7. As a player, I want the action button to look held while I am reeling, so that input acknowledgement is immediate.
8. As a new player, I want the fight to begin in recovery rather than an immediate surge, so that I can establish the basic interaction first.
9. As a player, I want recovery to be a safe opportunity to reel, so that the fish's behavior creates a readable rhythm.
10. As a player, I want prolonged yielding during recovery to create line slack, so that releasing forever is not a winning strategy.
11. As a player, I want a surge to be clearly telegraphed before it becomes dangerous, so that failure depends on my response rather than surprise.
12. As a player, I want fish, rod, and line motion to announce a surge, so that I can read the world rather than stare only at the HUD.
13. As a player, I want a short audio cue during surge wind-up, so that the warning remains noticeable amid visual activity.
14. As a player, I want yielding during a surge to return tension toward safety, so that the intended response is understandable.
15. As a player, I want reeling during a surge to raise tension rapidly, so that ignoring resistance has a believable cost.
16. As a player, I want a surging fish to regain modest distance, so that yielding has a meaningful trade-off.
17. As a player, I want each surge to have a landing-progress floor, so that one surge cannot erase the entire fight.
18. As a player, I want landing progress to move smoothly, so that retrieval and fish resistance feel physical rather than stepwise.
19. As a player, I want line tension to change smoothly between phases, so that a phase transition never causes an unexplained instant loss.
20. As a player, I want a compact line-tension gauge, so that I can confirm whether the line is slack, safe, or under excessive tension.
21. As a player, I want the safe-tension range to be visually distinct, so that I understand the target condition at a glance.
22. As a player, I want the relevant side of the gauge to pulse while danger accumulates, so that an approaching loss is unmistakable.
23. As a player, I want tension communicated without mandatory numeric values, so that the fight remains experiential rather than spreadsheet-like.
24. As a player, I want a brief danger window at unsafe tension, so that one small mistake remains recoverable.
25. As a player, I want returning to safe tension to reduce accumulated danger quickly, so that successful correction is rewarded.
26. As a player, I want sustained excessive tension to break the line, so that high-tension failure has a believable cause.
27. As a player, I want sustained slack to let the fish throw the hook, so that low-tension failure is distinct and believable.
28. As a player who loses a fish, I want the result to name the cause, so that I know what happened.
29. As a player who loses a fish, I want a short corrective hint, so that the next attempt teaches rather than merely punishes me.
30. As a player who breaks the line, I want the journal to record a line break, so that the attempt is represented accurately.
31. As a player whose fish throws the hook, I want the journal to record that distinct outcome, so that different failures do not collapse into generic loss.
32. As a player who loses a fight, I want no fish added to inventory, so that inventory represents completed catches.
33. As a player who loses a fight, I want no lure, currency, durability, or progression penalty, so that the prototype remains consequence-light.
34. As a player who loses a fight, I want to cast again promptly, so that experimentation has low friction.
35. As a player nearing success, I want the hooked fish to remain attached to the hook and line, so that the physical relationship stays believable.
36. As a player, I want the hooked fish and hook to remain underwater until landing, so that hook-set is not visually confused with a completed catch.
37. As a player, I want reaching the landing threshold to end tension risk immediately, so that success is unambiguous.
38. As a player, I want a distinct landed-fish presentation, so that bringing in a fish feels different from merely moving it close.
39. As a player, I want catch inventory and journal updates to occur after the landed-fish presentation, so that a hooked fish becomes a catch only when landing is complete.
40. As a first-time player, I want a brief prompt to hold during recovery, so that I can begin making progress without a modal tutorial.
41. As a first-time player, I want a prompt to release during the first surge wind-up, so that I learn the reel-or-yield rhythm in context.
42. As a first-time player, I want a cause-specific warning the first time either danger window begins, so that the gauge has an understandable meaning.
43. As a returning player in the same session, I want tutorial messages to stay out of the way, so that repeated fights remain clean.
44. As a player, I want lightly varied phase durations, so that I read fish cues rather than memorize a fixed sequence.
45. As a player, I want the beginner fish to remain predictable enough to learn, so that variation does not become noise.
46. As a developer, I want all fight outcomes driven by one authoritative model, so that HUD and spatial presentation cannot disagree about the result.
47. As a developer, I want fight scenarios to be deterministic under controlled configuration, so that player-visible outcomes can be validated reliably.
48. As a maintainer, I want fishing behavior to remain owned by One More Cast, so that the reusable pipeline does not absorb premature game-specific assumptions.

## Implementation Decisions

- Keep `REELING` as the cast-level state throughout the interactive fight.
- Model recovery, surge wind-up, and surge as internal fish-fight phases rather
  than additional cast-level states.
- Add `LANDED_FISH` between `REELING` and `RESULT`. Line break and thrown hook
  transition directly from `REELING` to `RESULT`.
- Introduce one game-owned fight model as the authority for phase timing, line
  tension, landing progress, both danger windows, surge count, and terminal
  outcome.
- The fight model accepts elapsed time and whether the contextual action is
  held. It exposes an observable snapshot for orchestration, presentation, and
  deterministic validation.
- Select lightly randomized phase durations when a fight begins; do not sample
  randomness continuously during model updates.
- Reeling during recovery moves line tension toward safe tension and advances
  landing progress. Yielding during recovery moves line tension toward slack.
- Reeling during a surge moves line tension rapidly toward excessive tension.
  Yielding during a surge moves tension toward safety while losing limited
  landing progress.
- Capture a progress floor for each surge so that surge loss cannot erase the
  whole fight.
- Accumulate high-tension and slack danger over time. Safe tension drains danger
  quickly. Crossing a threshold once never causes instant failure.
- Reuse the current contextual fishing action for casting, hook-set, and
  hold-to-reel behavior. Do not add a dedicated reel action.
- Treat keyboard and pointer press/release as equivalent held-input sources.
- The casting controller owns lifecycle orchestration and result recording. The
  spatial presentation and HUD consume fight output but do not calculate
  outcomes.
- Drive fish and line position from landing progress rather than elapsed reel
  animation time.
- Preserve the existing line endpoint, underwater hook, and fish-mouth
  attachment responsibilities throughout the fight.
- Use the existing placeholder fish, rod, line, and environment. Add only the
  procedural or temporary cues necessary to prove readability.
- Show one horizontal line-tension gauge with slack, safe, and high-tension
  regions. Do not require numeric tension or a visible failure countdown.
- Show three contextual tutorial messages once per play session. Do not persist
  tutorial completion in save data.
- Target a 12–18 second competent Bluegill fight containing two or three surges.
  The first surge receives a longer wind-up, and the fight begins in recovery.
- Resolve a landed fish through a brief locked-input presentation before adding
  it to inventory and recording the catch.
- Loss results record their distinct cause, add no inventory, consume no tackle,
  and return promptly to readiness.
- Keep all fishing-specific implementation in One More Cast in accordance with
  the established pipeline boundary.

## Testing Decisions

- Use the existing playable-world prototype validator as the single primary
  automated seam. Instantiate the full playable scene, drive contextual input,
  and assert player-visible state through the casting controller, HUD, and
  spatial provider.
- Test external gameplay behavior rather than the internal fields or private
  methods of the fight model. Deterministic fight configuration exists only to
  make observable scenarios repeatable.
- Extend the existing prior art that already validates cast input, hook-set,
  state labels, HUD controls, line shortening, underwater endpoints, and hook to
  fish-mouth attachment.
- Validate a successful recovery/surge sequence, modest surge distance loss and
  its progress floor, correction within each danger window, sustained
  high-tension line break, sustained-slack thrown hook, and landed-fish
  presentation before catch recording.
- Validate equivalent keyboard and on-screen button hold/release semantics.
- Preserve all current assertions around line endpoint ownership, underwater
  tackle, fish visibility, menu integration, and responsive HUD input.
- Time-box diagnosis of the local Godot headless crash. If it is environment-wide,
  record the reproduction and continue with manual editor validation rather than
  blocking implementation.
- Manually verify keyboard and pointer paths at multiple window sizes. Complete
  at least one catch, one line break, and one thrown-hook path.
- Manually verify that a competent successful fight falls near 12–18 seconds,
  contains two or three readable surges, and permits recovery from one brief
  mistake.

## Out of Scope

- Fish stamina or a second fight resource.
- Directional rod control, drag adjustment, line types, or tackle durability.
- Consuming lures, currency, or progression on failure.
- Multiple species-specific fight profiles beyond prototype Dock Bluegill
  tuning.
- Production fish art, final animation, final sound design, or final HUD
  skinning.
- Toggle-to-reel accessibility behavior, while avoiding choices that would
  prevent it later.
- Persisted tutorial completion.
- Save/load, crafting, weather, boat, economy, or broader progression work.
- Promoting fishing behavior into the reusable pipeline.

## Further Notes

- Before implementation, spend a short, fixed investigation on whether the
  Godot 4.7 crash affects a blank project and normal editor play. Document the
  usable validation route.
- The feature should be built in vertical slices: fight model, contextual input,
  spatial response, HUD teaching, outcome resolution, then end-to-end tuning.
- Update the fishing mechanics bible's current-prototype section only after the
  implementation matches the new behavior.
- Canonical language is defined in the root domain glossary. In particular,
  distinguish a hooked fish, a landed fish, and a recorded catch.
