# Fishing Game UI & Camera Presentation

## A Design Research Report on HUDs, Inventory, Tackle, Catch Presentation, and Camera Language

**Prepared July 2026**

---

> **Central thesis:** The best fishing-game interface does not merely display fishing data. It helps the player read water, understand tackle, feel line tension, recognize fish behaviour, and remember the catch—without covering the natural scene in instrumentation.

Fishing games have an unusual presentation problem. They must communicate hidden information—depth, tension, drag, fish energy, lure action, current, structure, species behaviour, and equipment compatibility—while preserving the fantasy of standing quietly beside water.

Poor interfaces solve this by displaying everything. Poor minimalist interfaces solve it by displaying almost nothing. Both weaken the experience.

The ideal system uses the **world, animation, sound, controller feedback, camera, and interface together**. Numbers and menus remain available when the player makes a deliberate equipment decision, but moment-to-moment fishing is communicated primarily through the rod, line, water, fish, and framing.

This report examines:

- *DREDGE*
- *Fishing Planet*
- *Call of the Wild: The Angler*
- *Dave the Diver*
- *Sega Bass Fishing* and *Sega Marine Fishing*
- *Reel Fishing*
- *Webfishing*
- *Ultimate Fishing Simulator*
- *Legend of the River King*
- Adjacent games with strong inventory and presentation ideas

The final sections convert those observations into a practical UI and camera framework for a modern fishing RPG.

---

# Executive Summary

## The best ideas by category

| Category | Best reference | What it teaches |
|---|---|---|
| Spatial inventory | *DREDGE* | Inventory can be a tactile planning game when shape, capacity, damage, and value share one visual language. |
| Equipment simulation | *Fishing Planet* | Rod, reel, line, terminal tackle, lure, and bait compatibility can create meaningful buildcraft. |
| Open-world presence | *Call of the Wild: The Angler* | First-person casting and travel create a strong feeling of inhabiting a fishing destination. |
| Catch spectacle | *Sega Bass Fishing* | Fish should become visually legible and exciting during the fight, not remain an invisible force beneath a flat surface. |
| Quiet presentation | *Reel Fishing* | Underwater observation, lodge presentation, magazines, records, and aquariums can make catches part of a lifestyle. |
| Characterful menus | *Dave the Diver* | A phone or personal device can unify menus while expressing character and world. |
| Catch-to-economy clarity | *Dave the Diver* and *DREDGE* | The interface should immediately explain what a catch is useful for. |
| Social ease | *Webfishing* | Minimal controls and readable social presentation can make fishing a shared hangout activity. |
| Field-journal fantasy | *Legend of the River King 2* | Collections are strongest when they feel like naturalist knowledge rather than abstract completion. |
| Platform adaptation | *DREDGE* mobile | A strong interface should be redesigned around its platform rather than merely scaled down. |

## Five rules to carry forward

1. **The natural view is the primary HUD.** Water, rod bend, line angle, animation, sound, and vibration should communicate the fight before meters do.
2. **Inventory should explain relationships.** Players must understand why a rod, reel, line, hook, bait, or lure works together without consulting an external guide.
3. **Cameras should change by activity.** Exploration, casting, lure presentation, fighting, landing, and celebration have different framing needs.
4. **The caught fish deserves a presentation sequence.** Identification, scale, condition, personality, record status, journal context, and uses should be readable within seconds.
5. **Complexity belongs in deliberate spaces.** Detailed comparison is welcome in a tackle box, lodge, workbench, or pause menu. It should not overwhelm the bank during a quiet cast.

---

# Part I — The Unique UI Problem of Fishing Games

## Fishing contains mostly invisible information

In a shooter, the target is visible. In a platformer, the jump is visible. In a driving game, the road is visible.

In fishing, many important variables are hidden:

- Whether fish are present
- What depth they occupy
- Whether they noticed the lure
- Whether a nibble is serious
- How securely the hook is set
- How close the line is to failure
- Whether the fish is turning toward cover
- Whether the lure is moving correctly
- Whether the tackle is suitable
- Whether current or wind is changing the presentation

This creates an interface temptation: expose all of it through icons, bars, alerts, sonar, outlines, and text.

That produces information, but can destroy mystery.

The objective is not maximum transparency. It is **legible uncertainty**. The player should have enough evidence to form a hypothesis, but not perfect knowledge.

## The four presentation layers

A strong fishing game communicates through four layers, in this order:

1. **World feedback** — Ripples, wakes, splashes, bubbles, current seams, insects, birds, shadows, vegetation, depth colour, and fish movement.
2. **Physical feedback** — Rod bend, line angle, slack, reel speed, drag sound, character posture, vibration, and lure motion.
3. **Contextual interface** — Small prompts, tension warnings, bite cues, landing opportunities, and temporary equipment information.
4. **Analytical interface** — Statistics, comparisons, journal records, habitat data, compatibility, maps, and progression.

Many games reverse this hierarchy. The player watches meters instead of water.

---

# Part II — Case Studies

# 1. DREDGE

## What works

*DREDGE* has one of the clearest and most integrated inventories in the genre.

Its cargo hold is not a list. It is physical space. Fish have shapes. Engines, rods, lights, research materials, and quest items compete for room. Damage can block cells. Arrangement communicates:

- Capacity
- Opportunity cost
- Risk
- Route planning
- Equipment loadout
- Catch value
- Urgency to return

The same visual grammar controls progression and immediate decision-making.

The developers explored more conventional upgrade menus before arriving at a more loadout-oriented system. The finished boat acts as a readable build. The game was later substantially redesigned for Apple platforms rather than simply shrinking the desktop UI.

## What works less well

- Packing can become routine after optimal patterns are learned.
- Large catches can feel like awkward shapes before they feel like animals.
- Fishing interactions are accessible but light compared with dedicated simulations.
- Repeated minigames become predictable.
- The map is not always present enough in peripheral navigation.

## What to borrow

- Spatial capacity rather than weight alone
- Equipment occupying the same planning space as cargo
- Damage visibly altering capacity
- Clear tool-to-fishing-type relationships
- Strong silhouettes
- The player’s boat or pack as a readable build

## What to change

For a River King-like game, use spatial inventory only where it enhances fantasy:

- Tackle box
- Creel
- Boat storage
- Camp pack
- Aquarium transport
- Research samples

The fish should remain emotionally primary.

---

# 2. Fishing Planet

## What works

*Fishing Planet* demonstrates authentic equipment relationships. A functional setup may include:

- Rod
- Reel
- Line
- Leader
- Hook or lure
- Sinkers, floats, feeders, or other terminal components
- Bait

The relationship among rod, reel, line strength, casting weight, drag, and terminal tackle produces genuine buildcraft. A setup is a system, not one power number.

It also communicates:

- Tackle configuration
- Cast aim and power
- Line tension
- Reel speed
- Drag
- Fish activity
- Keepnet capacity
- Time and weather
- Location and travel

## Where it struggles

The number of tutorials explaining how to equip rods reveals the central problem: the simulation model is richer than its explanatory interface.

Pain points include:

- Technically compatible components can still be poor together.
- Home storage, backpack storage, and trip inventory add friction.
- Similar items are hard to compare.
- The interface assumes fishing vocabulary before teaching the model.
- Shopping, storage, loadouts, and travel restrictions can punish experimentation.
- Players may have to leave a destination to fix a setup error.

## What to borrow

- Real component relationships
- Multiple complete rod loadouts
- Technique-specific builds
- Meaningful line, reel, and rod balance
- Weather and time forecasting
- Species-specific tackle logic

## What to avoid

- Hidden compatibility exams
- External-guide dependency
- Punishing experimentation
- Showing every numerical attribute with equal emphasis
- Confusing storage transfers

## Better solution: a visual compatibility chain

Display the setup horizontally:

`Rod → Reel → Main line → Leader → Terminal rig → Hook/lure → Bait`

Each connection communicates:

- **Excellent match**
- **Usable compromise**
- **Valid but risky**
- **Incompatible**

Selecting a warning explains the physical reason:

- Reel drag exceeds safe line load
- Lure is too light for the rod
- Hook is too large for the target
- Leader is too visible in clear water
- Float capacity is insufficient
- Line diameter reduces casting distance

The interface should teach fishing knowledge rather than remove it.

---

# 3. Call of the Wild: The Angler

## What works

*The Angler* excels at environmental presence. Travelling through reserves, walking shorelines, using vehicles and boats, and casting in first person make fishing feel located in a world rather than selected from a menu.

Its later addition of a third-person vehicle camera in response to motion-sickness concerns is a useful reminder that camera choice is an accessibility feature, not just an aesthetic preference.

## What does not work

- Long travel can become dead time.
- First-person fishing can obscure the body, bank, and fish position.
- Inventory restrictions may feel arbitrary.
- Some UI feels like a general open-world layer rather than fishing-specific information architecture.
- If the fish remains offscreen, fighting becomes meter management.

## What to borrow

- World-scale immersion
- First-person casting
- Equipment visible in hand
- Exploration and fishing in one continuous space
- Camera options for travel
- Scenic moments with little HUD

## What to change

Use a context-sensitive hybrid:

- First person for walking, observing, aiming, and casting
- Over-shoulder or offset first person during retrieval
- Dynamic side or three-quarter framing during major fights
- Close presentation during landing
- Optional locked first-person mode for simulation players

The player should retain embodiment without hiding the game’s most important animal.

---

# 4. Dave the Diver

## What works

*Dave the Diver* is not a traditional rod-and-line game, but it excels at converting caught fish into readable economic and narrative objects.

Strong choices include:

- Smartphone menu hub
- Clear separation between diving and restaurant work
- Recognizable fish silhouettes
- Strong colour and animation hierarchy
- Immediate collection feedback
- Menus tied to character and humour
- Catch quality affecting value
- A clear route from fish to dish to profit to upgrade

The phone makes unrelated systems feel like one personal object rather than a developer dashboard.

## What does not work

As its management layers grow, players have asked for:

- Recipe favourites
- Ingredient requirement markers
- Better filters
- Better cross-screen information
- Less repeated navigation among farm, fish farm, staff, dispatch, and recipes

The problem is **relationship visibility**. The game knows how ingredients connect to recipes and systems, but does not always show that relationship at the point of decision.

## What to borrow

- One characterful device for meta-systems
- Strong fish silhouettes
- Catch-quality presentation
- Explicit catch-to-use connections
- Comedic celebration without sacrificing usability
- Clear post-catch hierarchy

## What to improve

Every fish should show relevant downstream links:

- Tracked quest
- Favourite recipe
- Research requirement
- Aquarium need
- Personal-record potential
- NPC request
- Current market demand

The player should not memorize disconnected menus.

---

# 5. Sega Bass Fishing and Sega Marine Fishing

## What works

The Sega arcade games understand one principle many simulations forget:

> **The fish is the star.**

Underwater cameras reveal:

- Lure
- Target fish
- Vegetation and structure
- Strike
- Direction changes
- Jumps
- Near misses
- Scale and aggression

The camera behaves like sports broadcasting. It chooses the angle that best communicates drama rather than remaining locked to a literal human viewpoint.

## What does not work

- Constant underwater knowledge removes mystery.
- Cuts can become repetitive.
- The game can feel like action spectacle rather than fishing.
- Exaggerated sound and prompts may overwhelm quiet players.
- Behaviour can become pattern recognition instead of ecological reading.

## What to borrow

- Fish visibility at decisive moments
- Camera cuts as reward
- Clear lure-action depiction
- Underwater environmental structure
- Dramatic jumps and runs
- Strong scale communication

## What to change

Use underwater shots sparingly:

- Brief strike glimpse
- Naturally clear water
- Near-shore sight fishing
- Companion or tool observation
- Post-catch replay
- Trophy encounter climax
- Aquarium or journal reconstruction

Never grant permanent omniscience.

---

# 6. Reel Fishing

## What works

Classic *Reel Fishing* treats fishing as a quiet lifestyle.

Important ideas include:

- Naturalistic backgrounds
- First-person casting
- Underwater bite and lure views
- Lodge menu hub
- Fishing magazines with tips and seasonal information
- Records
- Tackle management
- Aquariums where fish can be watched and cared for

The rhythm is strong:

`Lodge → Plan → Fish → Return → Record → Observe`

The aquarium turns a catch from a result screen into a continuing presence.

## What does not work

- Mixed-media visuals could feel inconsistent.
- Difficulty sometimes exceeded the feedback available.
- Long fights became repetitive.
- Fixed positions limited agency.
- Fish could follow obvious repeated patterns.
- Realistic rendering with stiff animation made fish feel flat.

## What to borrow

- Home space organizing the fishing identity
- Seasonal advice through in-world media
- Aquarium and specimen care
- Underwater views for anticipation
- Records contextualized inside the lodge
- Calm audiovisual pacing

## What to improve

Prioritize coherent style and excellent motion over realism. A simplified fish with natural movement feels more alive than a photorealistic fish following a stiff path.

---

# 7. Webfishing

## What works

*Webfishing* proves fishing can be a low-pressure social interface.

Its strengths include:

- Immediate readability
- Simple controls
- Expressive avatars
- Compact social space
- Fishing that allows conversational gaps
- Visible catches and playful collection
- Strong nostalgic identity

Fishing gives players time to talk in a way combat usually does not.

## What does not transfer directly

- Mechanical simplicity alone cannot carry a deep single-player RPG.
- Social novelty supports repetition that may feel thin alone.
- The low-fidelity style works because the entire game commits to it.

## What to borrow

- Low-friction multiplayer
- Fishing animations readable at a distance
- Easy catch sharing
- Simple emotes and props
- Quiet presence rather than pressure

---

# Part III — Inventory Systems

# Inventory has four different jobs

Fishing games often force one inventory to manage four distinct categories:

1. **Loadout** — What is currently being used
2. **Tackle storage** — What might be switched to
3. **Catch storage** — Fish currently retained
4. **Adventure items** — Food, quest objects, tools, and materials

This causes clutter.

Use connected physical containers rather than one giant bag.

## Recommended container model

| Container | Contents | Purpose |
|---|---|---|
| On-body quick slots | Active rod, net, camera, small tool | Immediate actions |
| Tackle box | Lures, hooks, floats, weights, bait, leaders | Technique changes |
| Rod rack | Complete saved setups | Fast strategic switching |
| Creel/livewell | Retained catch | Capacity and conservation choices |
| Field pack | Food, clothing, repair kit, quest objects | Exploration preparation |
| Home storage | Full collection and reserves | Long-term organization |
| Journal/device | Knowledge, maps, records, requests | Information, not physical clutter |

## Saved rod setups

Players should save complete rigs with personal names:

- Creek Float
- Light Trout Spinner
- Deep Lake Jig
- Evening Fly
- Heavy Catfish
- Estuary Bottom Rig

A saved setup stores:

- Rod
- Reel
- Line
- Leader
- Terminal tackle
- Hook or lure
- Bait
- Drag preset
- Float depth
- Notes and target tags

Switching should be fast. Editing should be deep.

## Four necessary inventory views

### Physical view

Shows actual space and container logic.

Best for tackle boxes, creels, cargo, and packs.

### Comparison view

Shows selected attributes side by side.

Best for rods, reels, line, clothing, and boats.

### Relationship view

Shows what an item works with and why.

Best for tackle compatibility, recipes, quests, target fish, and research.

### Collection view

Shows discovery and personal history.

Best for fish, insects, plants, lures, trophies, and photographs.

No single screen should do all four.

---

# Part IV — What Makes Inventory Feel Good

## Strong silhouettes

A crankbait, float, fly, spoon, hook, worm, reel, and rod should be recognizable without text.

## Stable item locations

Frequently used items should remain where the player placed them. Auto-sort should be optional and reversible.

## Comparison by consequence

Do not emphasize every statistic. Emphasize what changes:

- Casting distance increases
- Lure control decreases
- Fish may detect the line more easily
- Break risk falls
- Rod becomes less responsive
- Hook-up rate improves for smaller fish

## Contextual filters

Useful filters include:

- Compatible with current rod
- Suitable for tracked fish
- Recommended for this water
- Used recently
- New
- Favourite
- Quest-related
- Present at current location
- Affordable
- Technique
- Water layer

## Experiment protection

Allow bad experiments without wasting half an hour.

Possible tools:

- Free test pond
- Workbench simulation
- Soft warnings
- Refund window
- Loaner tackle
- Local shop advice
- “Complete this rig” command
- Automatic substitution for minor missing parts

## Memory support

Remember:

- Last bait used here
- Last successful lure
- Recent catches
- Favourite rigs
- Personal notes
- Seasonal history
- Lost fish
- NPC recommendations

Mastery should accumulate inside the game.

---

# Part V — HUD Design

# Three HUD modes

## Exploration HUD

Recommended:

- Small contextual objective
- Time and weather on demand
- Subtle compass or landmarks
- Interaction prompts
- Active tool
- Stamina only when relevant

Avoid:

- Permanent minimap
- Large quest tracker
- Constant fish radar
- Full hotbar
- Floating resource icons

## Fishing HUD

Recommended:

- Cast aim and estimated landing point
- Current setup shorthand
- Retrieve speed
- Float depth or lure layer when relevant
- Subtle tension state
- Contextual action
- Environmental feedback

Avoid:

- Giant tension bars
- Fish health
- Exact hidden fish distance
- Species identification before landing
- Flashing alerts

## Fight HUD

It should become **simpler**, not busier.

Priority:

1. Rod bend
2. Line angle
3. Reel and drag sound
4. Haptics
5. Small peripheral warning
6. Obstacle or landing prompt

The player’s eyes should remain on the fish and line.

## Better tension feedback

Most games use a bar. It works, but players stare at it.

Combine:

- Rod bend
- Line highlight near the rod tip
- Reel strain audio
- Trigger resistance
- Haptic pulses
- Character stance
- Water spray and line vibration
- Peripheral vignette only near danger

An optional accessibility meter remains available.

| State | World feedback | UI feedback |
|---|---|---|
| Slack | Line droops; reel softens | Brief slack icon |
| Productive | Rod loaded; stable drag | No warning |
| High | Rod bends deeply; line sings | Amber peripheral pulse |
| Critical | Severe strain; drag chatters | Red pulse and sharp cue |
| Abrasion risk | Line crosses cover | Localized scrape cue |
| Landing opportunity | Fish rolls near surface | Net prompt beside fish |

---

# Part VI — Camera Presentation

# One camera cannot serve every activity

Fishing contains several spatial tasks. A rigid camera is rarely ideal.

## 1. Exploration camera

**Goal:** Inhabit the world.

- First person or close third person
- Wide enough view for banks and paths
- Gentle head movement
- Stable horizon
- Reduced-bob accessibility option
- Shoulder swap in third person

## 2. Water-reading camera

**Goal:** Inspect a location.

- Slight forward zoom
- Reduced HUD
- Optional polarized-glasses effect
- Focus between near surface and distant structure
- Shoreline lean or crouch
- Water and wildlife audio emphasis

It should encourage observation, not reveal fish icons.

## 3. Casting camera

**Goal:** Show target, trajectory, obstacles, and distance.

- Over-shoulder or first person
- Visible rod tip
- Subtle landing reticle
- Arc only when requested
- Wind/current shown through environment
- Stable camera during power input

Avoid body obstruction, camera whipping, bright permanent arcs, and hotspot snapping.

## 4. Retrieve camera

**Goal:** Preserve the relationship among player, lure, structure, and water.

- Normal player camera
- Optional gentle lure focus
- Surface disturbances framed clearly
- Underwater glimpses only in appropriate conditions
- No constant cinematic cutting

## 5. Fight camera

**Goal:** Make the fish-line relationship legible.

Recommended hybrid:

- Begin in player view
- Widen when direction changes
- Offset toward the line
- Reveal fish during jumps and surface runs
- Use short cinematic inserts for exceptional moments
- Never remove control during important input
- Preserve screen direction

### The 180-degree rule

If a fish runs left, a cut must not suddenly depict it running right unless it turns. Breaking screen direction makes the fight unreadable.

## 6. Landing and catch camera

**Goal:** Give the animal scale, identity, and dignity.

Sequence:

1. Fish approaches bank or boat.
2. Camera lowers toward water.
3. Net or hand interaction occurs.
4. Fish is shown beside a scale reference.
5. Species and record information appear.
6. Keep/release decision occurs.
7. Release shows recovery and departure.

Do not teleport immediately from the fight to a static menu.

---

# Underwater Cameras

## They work when

- Water is naturally clear
- The player is sight fishing
- They provide a brief strike reveal
- They teach lure action
- They offer a post-catch replay
- They belong to a specific tool
- They are earned through equipment or knowledge
- They communicate structure
- They celebrate rare encounters

## They fail when

- They provide permanent perfect knowledge
- They become optimal in every situation
- They remove anticipation
- Fish visibly orbit the lure
- Camera movement disconnects the player from the rod
- They spoil species and size
- They become passive viewing rather than fishing

> Treat underwater vision like punctuation, not prose.

---

# Part VII — Catch Presentation

# The catch screen is one of the game’s most important screens

A catch resolves:

- Location choice
- Equipment choice
- Presentation
- Timing
- Fight
- Risk
- Luck
- Knowledge

Reducing this to `Trout — 1.2 kg — $14` wastes the climax.

## Information hierarchy

### First: recognition

- Species
- Clear fish image or model
- Size and weight
- Record status

### Second: meaning

- New species
- Personal best
- Trophy class
- Quest relevance
- Unusual condition
- Rare variation
- First catch here

### Third: story

- Location
- Time
- Weather
- Tackle
- Fight duration
- Behaviour note
- Photograph
- Journal update

### Fourth: decision

- Release
- Keep
- Donate
- Photograph only
- Aquarium
- Quest hand-in
- Cook
- Sell

Details should expand progressively rather than arriving as one wall of data.

## Fish-model priorities

1. Correct silhouette
2. Natural body flex
3. Gill and fin motion
4. Wetness and light response
5. Weight
6. Scale
7. Species-specific behaviour
8. Fine texture

High-resolution scales do not compensate for stiff motion.

## Keep/release presentation

Do not universally frame release as good and retention as bad. Communicate context:

- Regulations
- Population health
- Food or quest need
- Trophy significance
- Livewell capacity
- Fish condition
- Conservation benefit

The choice should be informed, not moralized.

---

# Part VIII — Menus and Information Architecture

# Recommended top-level structure

A phone, journal, tackle binder, or lodge desk can contain:

1. Map
2. Journal
3. Tackle
4. Requests
5. Weather and water
6. Records
7. Relationships
8. Settings

## Map

Show:

- Named waterways
- Access paths
- Player notes
- Past catches
- Depth only where learned
- Current and water-level observations
- Weather
- NPC information
- Camps and transport
- Regulations
- Habitat rather than fish icons

## Journal

Each fish entry contains:

- Illustration or model
- Known range
- Habitat clues
- Preferred water layer
- Seasonal activity
- Food
- Successful tackle history
- Personal records
- Catch locations
- Local stories
- Confidence level for uncertain facts

Unknown information should appear as questions, not locked boxes.

## Tackle

Support:

- Saved rigs
- Component comparison
- Compatibility graph
- Target recommendations
- Test mode
- Automatic completion
- Favourites
- Recent use
- Personal labels

## Requests

Organize by:

- Person
- Region
- Species
- Time sensitivity
- Tracked status
- Natural compatibility with current destination

Avoid a generic wall of errands.

---

# Part IX — What Does Not Work

## 1. Cockpit HUD

Too many meters and icons turn fishing into operating an instrument panel.

## 2. Hidden simulation

A complex system is not deep when cause and effect cannot be understood.

## 3. Universal stat ladders

A +42 rod replacing a +36 rod is weak progression.

## 4. Inventory punishment

Returning home for one forgotten component discourages experimentation.

## 5. Permanent underwater omniscience

Seeing every fish removes the mystery of water.

## 6. Invisible fish fights

A tension bar alone does not present an animal.

## 7. Unskippable celebrations

Rare fish deserve ceremony. The fiftieth minnow needs a fast flow.

## 8. Contextless results

Weight and price do not preserve memory.

## 9. Menu duplication

A fish should not have disconnected representations in inventory, journal, recipes, quests, aquarium, and market.

## 10. Camera disorientation

Cinematic presentation must preserve line direction, fish direction, and obstacles.

## 11. Tiny text and colour-only warnings

Fishing games are often played on televisions and handhelds. Use scale, contrast, icons, motion, sound, and haptics.

## 12. Fake minimalism

Removing UI without adding world, animation, and audio feedback only makes the game obscure.

---

# Part X — Unified Design Proposal

# Presentation philosophy

The game should feel like a **naturalist field adventure**, not a sports broadcast or spreadsheet.

Visual language:

- Warm and field-guide inspired
- Paper, tackle labels, handwritten marks, and topographic forms
- Clean modern interaction beneath the texture
- Fish illustrations paired with living 3D models
- Strong silhouettes
- Minimal screen-centre UI
- Information expanding from context

# Moment-to-moment screen

Default:

- No permanent minimap
- No permanent health or tension bars
- Small active-setup indicator
- Time/weather one input away
- Objective collapsed to one line
- Prompts near relevant objects
- Water occupying as much screen as possible

# Tackle box

Combine *DREDGE* and simulation buildcraft:

- Physical tackle-box grid
- Saved rigs in a rod rack
- Component compatibility chain
- Target-species filter
- Personal labels
- Explanations of compromise
- No destructive experimentation costs

# Journal

Combine *River King 2*, *Reel Fishing*, and map memory:

- Illustrated field guide
- Personal photographs
- Full catch history
- Map pins created by experience
- Rumours and evidence
- Favourite catches
- Lost-fish stories
- Ecological notes

# Camera

Combine *The Angler*, Sega arcade fishing, and *Reel Fishing*:

- Embodied exploration
- Clear casting
- Grounded retrieval
- Dynamic but restrained fighting
- Rare underwater inserts
- Detailed landing
- Optional catch photography

---

# Part XI — Screen Flow

## Starting an outing

`Home/Lodge → Weather board → Map → Rod rack → Tackle box → Pack → Depart`

## At the water

`Observe → Select rig → Adjust tackle → Cast → Retrieve → Fight → Land`

## Catch resolution

`Recognition → Record → Photograph → Keep/release → Journal update`

## Return

`Store tackle → Process catch → Requests/market/cooking → Aquarium or journal → Plan next trip`

Context should persist. Opening the journal after a catch should open that fish. Opening tackle from a fish entry should filter relevant gear. Opening the map should show the catch location.

---

# Part XII — Prototype Specification

# Goal

Prove a fishing fight can be:

- Visually readable
- Mechanically deep
- Mostly meter-free
- Exciting without noise
- Supported by clear tackle management

## One environment

A forest river bend containing:

- Shallow riffle
- Deep pool
- Fallen log
- Undercut bank
- Gravel bar
- Shore vegetation

## Five fish behaviours

- Small schooling fish
- Cautious trout
- Aggressive ambush fish
- Bottom-holding fish
- Large cover-seeking trophy fish

## Three techniques

- Float
- Spinner
- Fly

## Required UI

- Saved-rig selector
- Compatibility chain
- Minimal cast UI
- Multimodal tension feedback
- Catch presentation
- Journal entry
- Catch map pin

## Required cameras

- Exploration
- Water inspection
- Casting
- Fight
- Landing
- Photograph

---

# Part XIII — Evaluation Checklist

1. Can the player identify line trouble without staring at a meter?
2. Can the player understand why a setup is weak?
3. Can a beginner assemble a functional rig without a guide?
4. Can an expert inspect detailed statistics?
5. Does the screen remain beautiful while waiting?
6. Is the fish visible enough to feel alive but hidden enough to preserve mystery?
7. Does the camera maintain line and fish direction?
8. Does a catch feel larger than its sale price?
9. Can the player trace a fish to recipes, quests, records, and journal entries?
10. Does inventory encourage planning rather than housekeeping?
11. Can common catch screens resolve quickly?
12. Can rare catches receive ceremony?
13. Are visual warnings also communicated through sound or vibration?
14. Can HUD elements be resized or disabled?
15. Does controller navigation work without cursor emulation?
16. Does the UI work at television distance?
17. Does the journal remember player learning?
18. Does the map show habitat rather than only objectives?
19. Can the player experiment without severe punishment?
20. Does the interface make the player look at the water?

---

# Part XIV — Feature Priorities

## Must have

- Saved complete rod setups
- Clear equipment compatibility
- Strong fish silhouettes
- Contextual catch presentation
- Minimal fishing HUD
- Dynamic fight camera
- Personal journal
- Catch history on map
- Fast common-catch flow
- Deep optional comparison
- Controller-first navigation
- Scalable accessibility feedback

## Should have

- Physical tackle-box organization
- Aquarium or lodge display
- Catch photography
- Rumour tracking
- Favourite gear and species
- Water-reading mode
- Exceptional-catch replays
- Multiple HUD presets
- Platform-specific layouts

## Could have

- Persistent individual trophy fish
- Multiplayer catch photography
- Player-authored journal notes
- Shared fishing reports
- Voice or haptic bite accessibility
- Companion commentary
- In-world fishing magazine
- Tackle-box decoration

## Avoid initially

- Full sonar simulation
- Hundreds of nearly identical items
- MMO-style hotbars
- Permanent underwater camera
- Complex crafting
- Auction house
- Live-service inventory pressure
- Huge world before one shoreline feels excellent

---

# Final Recommendations

The strongest fishing-game presentation would combine:

- **The spatial clarity of *DREDGE***
- **The equipment relationships of *Fishing Planet***
- **The world presence of *The Angler***
- **The fish spectacle of *Sega Bass Fishing***
- **The lodge and aquarium fantasy of *Reel Fishing***
- **The characterful menu language of *Dave the Diver***
- **The social ease of *Webfishing***
- **The naturalist journal of *Legend of the River King 2***

But it should not copy any one game wholesale.

> **Keep complexity in the tackle, knowledge, and ecosystem. Keep the view of the water calm. Let cameras reveal the fish only when seeing it creates the most meaning.**

A player should finish an outing remembering:

- Where they stood
- What the water looked like
- Why they chose the lure
- How the fish behaved
- Where the line nearly broke
- What the fish looked like in hand
- What the catch meant afterward

If they remember only a tension meter and an inventory value, the presentation has failed.

---

# Source Notes

- Black Salt Games, *DREDGE*: https://www.blacksaltgames.com/
- Game Developer, “How Black Salt Games made spooky fishing RPG, Dredge”: https://www.gamedeveloper.com/design/trawling-in-the-deep-how-black-salt-games-made-spooky-fishing-rpg-i-dredge-i-
- Apple Developer, *DREDGE* platform redesign: https://developer.apple.com/videos/play/meet-with-apple/247/
- Fishing Planet Wiki, balanced tackle setup: https://wiki.fishingplanet.com/Building_a_balanced_tackle_setup
- Fishing Planet Wiki, tutorial: https://wiki.fishingplanet.com/Tutorial
- *Call of the Wild: The Angler*, patch 1.5.5 camera notes: https://cotwtheangler.com/news/patch-1-5-5-is-live/
- Unity, *Dave the Diver* production case study: https://unity.com/resources/dave-diver
- Game Accessibility Nexus, *Dave the Diver* accessibility review: https://www.gameaccessibilitynexus.com/blog/2024/02/13/dave-the-diver-deaf-game-review/
- Interface In Game: https://interfaceingame.com/
- Naftis, Tsatiris, and Karpouzis, “How Camera Placement Affects Gameplay in Video Games”: https://arxiv.org/abs/2109.03750

## Interpretive note

The recommendations and evaluations are design analysis based on documented systems, developer commentary, reviews, and observed interaction patterns. They are not claims of explicit developer intent.
