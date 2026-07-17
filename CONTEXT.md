# One More Cast Domain

One More Cast is a fishing game built around believable fishing concepts and
approachable player decisions.

## Product Shape

**Weathered field journal**:
The visual language of One More Cast: warm paper and ink surfaces, deep lake-blue accents, and muted moss and brass signals that make fishing knowledge feel collected and lived-in.
_Avoid_: Arcade HUD, coastal utilitarian, storybook UI

**Field-journal typography**:
The reading system pairing Cormorant Garamond for discovery-facing titles and Atkinson Hyperlegible for live fishing information and controls.
_Avoid_: Default UI font, single-font treatment

**Fishing homes**:
The three stable places for fishing information: a field card for outing context, an action strip for the immediate decision, and a notebook drawer for deeper records.
_Avoid_: Monolithic HUD, permanently expanded notebook

**Fishing palette**:
The semantic color language of the fishing interface: lake ink for quiet structure, paper warmth for records, moss for confirmation, brass for attention, and rowan red for danger.
_Avoid_: Decorative rainbow palette, universal glow, danger-colored confirmation

**Light physicality**:
The interface's restrained material character: field-note cards, dock tags, and subtle paper-and-ink cues that suggest a lived-in fishing practice without becoming a literal desk simulation.
_Avoid_: Flat generic overlay, skeuomorphic desk

**Causal micro-feedback**:
Brief, state-linked interface motion that confirms a fishing action or observation without competing with water-reading; it includes an equivalent reduced-motion presentation.
_Avoid_: Ambient UI motion, decorative screen shake, looping celebration

**Field-record reveal**:
The quiet catch or loss presentation that records an encounter while keeping its fish and water context present, rather than converting it into a generic reward screen.
_Avoid_: Loot pop-up, detached inventory reward

**Compact foundation**:
The first complete, release-sized game area: a dense, self-contained fishing
RPG experience that is satisfying on its own and establishes systems and
content patterns that can later extend into a full watershed.
_Avoid_: Demo, throwaway prototype, whole game

**Local need**:
A human-scale problem or responsibility rooted in the home community that gives
ordinary fishing outings emotional and practical meaning.
_Avoid_: Main quest, epic stakes, generic objective

**Watershed mystery**:
An exceptional fish or natural phenomenon whose incomplete, contradictory local
accounts provide the compact foundation's long-term direction.
_Avoid_: Boss fish, legendary loot, final objective

**Home water**:
The continuous, familiar lake surrounding the community and forming the compact
foundation's primary place of fishing, travel, and return.
_Avoid_: Map, level, fishing stage

**Tree line**:
The layered pine and shore-forest silhouette along the inaccessible shore and
far bank that frames the home water and suggests its compact edge without
acting as the physical traversal boundary.
_Avoid_: Invisible wall, fence, map border

**Mountain backdrop**:
The restrained, layered low-poly mountain silhouettes beyond the tree line that
encircle the home water, give it a recognizable basin and regional identity,
and visually contain the world without adding collision or a traversal rule.
_Avoid_: Playable range, collision wall, dramatic vista set piece

**Pine kit**:
The small family of compatible, weathered low-poly pine variants used to
compose the tree line: a tall landmark pine, a standard pine, and a smaller or
leaning pine.
_Avoid_: One repeated tree, generic foliage pack, foliage system

**Non-interactive scenery**:
World dressing that strengthens the readability and atmosphere of a place
without adding collision, prompts, inventory, or a new gameplay rule.
_Avoid_: Obstacle, collectible, simulation system

**Micro-habitat**:
A small, authored section of the home water with distinct visible conditions,
fish presence, and fishing implications.
_Avoid_: Biome, zone, spot

**Fishing conditions**:
The small, readable set of circumstances that shapes fish presence for an
outing: micro-habitat, time of day, and rig or presentation.
_Avoid_: Spawn table, hidden modifiers, catch matrix

**Field journal**:
A context-rich record of fishing evidence and personal memories that helps the
player form and test hypotheses about the home water.
_Avoid_: Collection screen, checklist, bestiary

**Observation**:
A recorded piece of evidence from an outing, including a catch, fish sign,
bite, loss, or condition.
_Avoid_: Stat, unlock, progress point

**Expedition texture**:
Light, legible resistance around an outing—travel, passing time, and temporary
route or weather inconvenience—that makes return and shelter meaningful without
becoming a survival-management system.
_Avoid_: Survival loop, grind, chore system

**Home community**:
The small set of recurring people at the home water whose needs, practical
knowledge, and local accounts make fishing socially meaningful.
_Avoid_: Quest hub, NPC roster, task board

**Home Cottage**:
The modest, weathered shared working lakeside dwelling where the player
returns between outings and encounters the home community.
_Avoid_: Dockside cottage, base, player house

**Home Cottage Interior**:
The compact, separately loaded single-room interior of the Home Cottage where
the player reads the field journal and meets a community contact.
_Avoid_: House interior, home screen, cabin instance

**Mara Vale**:
The Home Cottage contact whose dockside-supper need gives the first outings a
local practical purpose.
_Avoid_: Quest giver, shopkeeper, generic NPC

**Knowledge-and-access progression**:
Advancement through learned fishing conditions, new presentations, trusted
relationships, and reachable micro-habitats rather than escalating equipment
statistics.
_Avoid_: Gear score, power curve, tier grind

**First complete loop**:
The first end-to-end player proof: receive a local need, choose a micro-habitat,
fish and learn from the result, record an observation, return home, and receive
a clue about the watershed mystery.
_Avoid_: Tutorial, technical demo, vertical-slice checklist

## Fishing

**Reeling**:
The player actively retrieves line to bring a hooked fish closer.
_Avoid_: Pulling, winding

**Yielding**:
The player deliberately stops retrieving line to manage tension while a hooked
fish resists.
_Avoid_: Resting, pausing

**Line tension**:
The strain carried through the fishing line between the rod and a hooked fish.
_Avoid_: Pressure, reel tension

**Safe tension**:
The range of line tension that keeps a hooked fish secure without risking a line
break.
_Avoid_: Green zone, ideal pressure

**Line slack**:
A lack of sufficient line tension that can allow a hooked fish to escape.
_Avoid_: Low pressure

**Recovery**:
A fish-fight phase in which the hooked fish offers light resistance and can be
reeled closer safely.
_Avoid_: Rest phase, easy phase

**Surge**:
A fish-fight phase in which the hooked fish pulls hard and rapidly increases
line tension if the player continues reeling.
_Avoid_: Attack, struggle phase

**Danger window**:
A short period during which unsafe line tension or slack must persist before the
hooked fish is lost.
_Avoid_: Instant failure, grace period

**Line break**:
A lost-fish outcome caused by sustained excessive line tension.
_Avoid_: Snap failure

**Thrown hook**:
A lost-fish outcome in which sustained line slack allows the hooked fish to
escape from the hook.
_Avoid_: Unhooked, slack failure

**Landing progress**:
How close a hooked fish is to being successfully brought in. A surging fish can
regain limited distance without erasing the whole fight.
_Avoid_: Reel progress, catch progress

**Hooked fish**:
A fish physically attached to the hook and still capable of escaping during the
fight.
_Avoid_: Catch, caught fish

**Water lens**:
A picture-in-picture cinematic view that follows the hooked fish during a fish
fight while the player's fishing controls remain visible and usable.
_Avoid_: Cinematic camera, fish cam, cutaway

**Shot policy**:
The authored mapping from a fish-fight change to the water-lens shot that
frames it; it preserves the hooked fish, its travel direction, and the active
fishing decision.
_Avoid_: Cutscene timeline, camera script

**Fish presence**:
The likelihood and character of fish activity in fishable water before a fish
is hooked.
_Avoid_: Visible fish, fish actor

**Fish sign**:
Indirect visible evidence of an unhooked fish, such as a shadow, wake, or
surface disturbance, without clearly revealing the fish itself. Ambient fish
signs establish life; lure-focused fish signs imply interest but do not
guarantee a bite.
_Avoid_: Fish spawn, visible fish

**Bite signal**:
The distinct indication that a fish has taken or struck the terminal tackle and
the player can attempt to set the hook.
_Avoid_: Fish sign, random ripple

**Dock Bluegill**:
The first authored fish species and the reference form for other small-bodied
fish in One More Cast.
_Avoid_: Generic fish, placeholder fish

**Landed fish**:
A fish that has completed the fight and reached the successful catch
presentation.
_Avoid_: Hooked fish, result

**Catch**:
The completed fishing outcome recorded after a landed fish is presented.
_Avoid_: Hooked fish
