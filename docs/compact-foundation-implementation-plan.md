# Compact Foundation Implementation Plan

## Outcome

Deliver the first complete loop described in the design philosophy while
preserving the existing believable lure-fishing model. Each set should be
playable and reviewable on its own; no set depends on a full watershed.

## Set 1: Make the lake a home water

**Goal:** Replace the generic prototype fishing rectangle with a memorable,
continuous place that supports meaningful location choice.

- Author the dock/shallows, vegetated inlet, and deep/rocky-bank micro-habitats
  around the existing lake.
- Give each micro-habitat visible water, shoreline, cover, and access cues.
- Replace the single fishable-water rule with named micro-habitat boundaries
  while keeping casting validation spatial and readable.
- Add a simple time-of-day state and an initial condition display; weather is
  visual only in this set.
- Preserve the existing cast, hook-set, reeling/yielding, tension, and landing
  loop without broadening it into fish AI or simulation.

**Proof:** A player can walk to at least two visually distinct places and see
which fishing conditions apply before casting.

## Set 2: Turn fishing results into evidence

**Goal:** Make fish presence and failure instructive rather than opaque.

- Define game-owned data for fish species, micro-habitat, time of day, and rig
  or presentation compatibility.
- Drive ambient fish signs and lure-focused signs from those conditions, using
  the semantic WaterSurface reaction boundary.
- Attach clear causes to missed bites, line breaks, and thrown hooks using the
  established fishing vocabulary.
- Add the first field-journal data model and UI for automatic observations:
  catch, sign, bite, loss, micro-habitat, time, and presentation.
- Keep pre-hook fish presence abstract and retain Dock Bluegill as the first
  authored hooked-fish reference form.

**Proof:** After an outing, the player can identify what happened and form one
new hypothesis about where or how to fish next.

## Set 3: Add choices that widen mastery

**Goal:** Prove knowledge-and-access progression without a gear-power ladder.

- Add one contrasting presentation after the lure rig, with a distinct readable
  loop and a real fishing purpose.
- Add a small initial species set whose preferences overlap enough to invite
  experimentation without creating a spreadsheet.
- Introduce one access unlock, such as a reopened path or trusted private bank,
  which exposes or improves a micro-habitat.
- Let journal evidence and a practical community contact point toward the new
  option; do not gate it behind anonymous quantity collection.

**Proof:** A player learns something with the first rig, gains a new option,
and uses the new option to make a qualitatively different fishing decision.

## Set 4: Build the return loop and mystery

**Goal:** Connect fishing to people and establish the long-term emotional pull.

- Create the compact home-community interaction layer for the local need,
  practical fishing contact, and local-story/ecology keeper.
- Give catches and observations a small number of meaningful dispositions:
  share, retain for the journal, or use to help someone. Avoid a grind economy.
- Implement a return-home beat that advances time, reacts to observations, and
  makes the dock feel safe and socially present.
- Seed the first contradictory watershed-mystery clue through an observation or
  conversation, not a lore dump.

**Proof:** A fishing result changes a relationship or understanding at home,
and the player has a reason to plan another outing.

## Set 5: Integrate and validate the first complete loop

**Goal:** Deliver a 20–30 minute coherent experience, then use player behavior
to decide whether to deepen the home water or begin planning its next region.

- Script the first local need, two viable micro-habitat choices, a successful
  catch or instructive loss path, journal recording, return interaction, and
  first mystery clue.
- Validate that every loss gives a readable cause and every required condition
  has an in-world cue.
- Test that no content requires combat, hunger management, weather knowledge,
  or external reference material.
- Run existing prototype validation alongside new automated checks for
  conditions, observation records, and access changes.
- Capture a short playthrough and conduct a focused feel review: can players
  name a place, explain a result, and choose a reason to return?

**Proof:** A new player can complete the first loop without explanation beyond
the game itself, and can describe a specific thing they learned about the home
water.

## Deliberately deferred

- Full watershed map, boats, and additional settlements.
- Weather-driven fish tables and seasonal simulation.
- Free-swimming fish AI, schooling, and underwater navigation.
- Combat, survival meters, and a conventional gear power curve.
- Large species counts, multiplayer, and endless-game features.

These are growth opportunities only after the compact foundation demonstrates
that players remember its places, understand its fishing outcomes, and choose
to return.
