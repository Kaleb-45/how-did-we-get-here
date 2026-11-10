# GAME_PLAN.md — "How Did We Get Here?" full game

Owner: Kaleb. Written Nov 10, 2026. Engine: Godot 4, web export.
This file is the design source for the full game. AGENT_SOURCE.md is still the record of how Kaleb makes choices. If the two files conflict, ask Kaleb.
Updated Nov 10, 2026 with Kaleb's answers to the conflict list C1–C16. Each answer is also recorded in AGENT_SOURCE.md.

## 0. How agents use this file

- Read this file and AGENT_SOURCE.md before any work.
- Build in the phase order in section 13. Do not skip ahead.
- **Skeleton first, tweaks later.** Until Phase C is done, do not polish, rebalance, or restyle. Gray boxes and plain text are correct.
- Every number goes in a data file. Every new number is real NASA data with a source link, or it is marked `"source": "PLACEHOLDER"`.
- Each section marks its open choices as **DEFAULT**. Use the default and keep building. List the defaults you used in your report so Kaleb can change them later. If there is no DEFAULT, ask one short question.

## 1. The game in one paragraph

The chief mission designer quits, and the general puts a person in charge of a real space mission: a scientist, the janitor, or a student. The player answers a few questions, builds the spacecraft, launches it, keeps it (and, at Mars, its crew) alive on the way, and then arrives and works at the destination. The inner voice guides the player in a nervous, funny first person. It is never wrong, but it only knows what its character knows. Every choice in the build changes what happens later. The game ends with a report to the general.

**Pillars**

1. Choices in Stage 1 have visible results in every later stage.
2. Execution matters. Timed button presses decide how well each key moment goes.
3. Real NASA numbers drive the limits.
4. Students can add their own content with data files, not code.

## 2. Player flow

```
Title
 → Setup questions (section 3)
 → STAGE 1: Build (section 5)
 → Review: "Does it all add up?"            ← exists today
 → CHECKPOINT 1
 → STAGE 2: Launch (section 6a)             ← short, timed presses (Space)
 → CHECKPOINT 2
 → STAGE 3: Flight (section 6b)             ← on the way: keep the crew and ship in order
 → CHECKPOINT 3
 → STAGE 4: Arrival (section 7)             ← orbit: shadow pass + science; surface: land and work
 → Report to the general (section 8)
 → Retry from checkpoint / Same design, new destination / Start fresh
```

What exists today: character select, a 3-choice build screen (solar, camera, antenna), the dashboard, the review screen, the walkable graybox ship (four rooms), the Mars shadow pass power event with the Reroute Power mini-game (it replaced the old dust storm), and the report. Keep all of it. The plan below grows it.

## 3. Setup questions

Ask these before Stage 1. One question per screen. The inner voice reacts to each answer.

| # | Question | Sets |
|---|---|---|
| 1 | What is your name? | Name on the report |
| 2 | Who are you? | Character = play level (section 9) |
| 3 | Where are we going? | Destination (section 4) |
| 4 | What is the mission for? | Mission goal: the 2–3 success rules shown as a checklist |
| 5 | What kind of rocket? | Launch vehicle: sets the launch sequence (how many moments, how tight) and its cost |

The launch vehicle does **not** change the mission limits. Budget max stays $671M (MAVEN's real total cost) and mass max stays 1,031 kg (MRO's real dry mass).

Question 5 is the "design the rocket" step. Keep it a choice of 3 launch vehicles in the skeleton. A deeper rocket builder is a later tweak.

## 4. Destinations

Five destinations in three groups. The skeleton builds group A first. All others come from the same data shape.

| Group | Destination | Arrival type | What makes it different |
|---|---|---|---|
| A. Orbit | Mars orbit (exists today) | orbit | Shadow passes, mapping, data downlink |
| B. Mars surface | Jezero Crater | surface | Old river delta: best science, rough ground |
| B. Mars surface | Gale Crater | surface | Low ground: more air to slow the landing |
| B. Mars surface | Arcadia Planitia | surface | Ice under the soil: water and oxygen, but cold |
| C. Outer planets | Europa (Jupiter) | flyby | Weak sunlight, strong radiation, long signal delay |

**DEFAULT:** the three Mars sites and Europa above. They are real NASA mission sites or study regions. Confirm each fact with a NASA source before it goes in the data file.

**Crew.** Mars missions have a crew on a ship that carries the spacecraft the player built. Europa has no crew, so it has no crew supplies.

**Different options per destination.** Each part in the build has an `allowed_at` list and can have per-destination numbers. Examples of the idea (source every number):

- Sunlight is weaker far from the Sun, so solar panels make less power at Mars and far less at Jupiter. Europa unlocks a nuclear power source (RTG).
- Surface missions need landing parts: heat shield, parachute, landing engine. Orbit missions do not show these.
- Far destinations need a bigger antenna for the same data rate.
- Europa needs radiation shielding. It adds mass.

## 5. Stage 1: Build

Grow the current build screen. Keep the live dashboard and the "review my spacecraft" step.

- **Part slots:** power, battery, instrument, antenna, computer, thermal (the heater), propulsion. Mars missions add life support for the crew (food, water, air). Surface missions add: heat shield, parachute, landing system, surface tools. Europa adds: radiation shield.
- **Each slot:** 2–3 versions. Each version has mass, cost, power, and one plain-English trade-off line.
- **Limits:** budget and mass are max limits. They must matter, but they must leave room to take risks.
- **Ripple line:** when the player changes a part, show one line that says what else changed. Example: "Bigger camera → more data → your antenna is now too slow."
- **Inner voice hint:** one "did you know" hint when the design has a mismatch. Never give the answer. How much the hint says depends on the level (section 9).
- **Blockers:** the player may launch with problems. The review screen lists them. Failing teaches.

## 6. Stages 2 and 3: Launch, then Flight

Launch and Flight are two separate stages. Launch is short and fast. Flight is long and is about care.

### 6a. Stage 2: Launch (new)

A side view of the rocket. A timeline of 4–5 moments: liftoff, max pressure, stage separation, fairing release, engine cutoff. Each moment is one **timed press** (section 12a). The player cannot move here, so the press key is **Space**.

- Perfect or Good: no loss.
- Miss: a cost, not an instant fail. Examples: lost fuel, a damaged panel, a slower trip.
- The launch vehicle from question 5 sets how many moments there are and how tight they are.
- Launch results carry into Flight. Example: lost fuel makes the trip longer, so supplies must last longer.

**Checkpoint 2** saves when the spacecraft is on its way.

### 6b. Stage 3: Flight (exists as the ship, grow it)

The player is on the way to the destination, inside the walkable ship. The job: keep everything in order until arrival.

The ship has five rooms: Bridge, Power room, Science bay, Comms room, and **Life Support**.

**Crew supplies** (Mars only; shown in Flight and Arrival only). Each one is a meter on the dashboard. Each one drops over the trip. Use NASA's real per-person daily numbers, with source links.

| Meter | Drops because | Station on the ship | Task to keep it up |
|---|---|---|---|
| Food | The crew eats every day | Life Support | Ration, or grow food if the player packed a garden |
| Water | Drinking and cooling | Life Support | Change the filter, fix a leak |
| Air | Breathing | Life Support | Swap the scrubber |

**Resources that also matter on the way** (two of the six; the six keep their exact names):

| Resource | Drops because | Station on the ship | Task to keep it up |
|---|---|---|---|
| Power | Distance from the Sun | Power room (exists) | Switch systems off and on, including the heater |
| Data | Instruments fill the storage | Science bay, Comms room | Collect, then send home before storage is full |

Heat has one mechanic only: the heater switch on the power panel. There is no heat meter and no thermal-panel task.

**How the trip plays.**
- The trip is split into legs. **DEFAULT:** 3 legs.
- Each leg has 2–3 routine tasks and 1 event (from `events.json`).
- Routine tasks are simple: walk to the station, press E, do one action. Some use a timed press (with E).
- Events are problems: antenna off target, water leak, solar flare. The Mars shadow pass is **not** a Flight event. It happens only in Mars orbit (section 7).
- A skipped task makes its meter drop faster. A meter at zero adds a finding and a damage cost. A meter that is red at the end can fail the mission (section 8).
- Time is sped up. The inner voice says how many real days each leg stands for.
- Trip length comes from the destination and the launch result. A longer trip uses more supplies.
- Stage 1 choices decide how hard this is. Small food store = strict rations.

**Checkpoint 3** saves at the end of the flight, before arrival.

## 7. Stage 4: Arrival

The type comes from the destination. What is left of the supplies from Flight is what the player starts with here. **Mission lifetime** means how long the spacecraft works after arrival.

**Orbit type (Mars orbit).** A timed press (E) for the orbit burn. Then the mission clock runs on the ship: this is the existing walk. The **Mars shadow pass** happens here, with the Reroute Power mini-game, and keeps its win/lose tests (AGENT_SOURCE.md section 6, items 7–9). The player also does 3 science passes. In each pass the player presses E when the target is in view (capture), then when the ground station is in view (downlink). Storage, power, and antenna speed limit how much science gets home.

**Surface type (three Mars sites).**
1. Landing: a chain of timed presses. Heat shield off, parachute out, landing engine on, touchdown. Misses cost fuel, damage, or distance from the target.
2. Surface work: the player gets out and walks around a small area, with the same controls as the ship. Timed presses use E. The player has a number of days.
3. Materials: the player collects and uses what the site has. Each site has its own list. Example: Arcadia Planitia has ice. A drill plus power turns ice into water and oxygen.
4. Each day costs power and supplies. The parts from Stage 1 decide how many days the player gets.
5. **DEFAULT:** 3 tasks per site: collect a sample, run one instrument, send the data home.

**Flyby type (Europa).** No crew and no landing. A chain of timed presses during one fast pass: point the instrument, capture, protect the computer from radiation, send the data. Signal delay means the player commits to actions early. **Open:** where the player stands during the Europa flyby (no crew ship). Ask before Phase B step 4.

## 8. Scoring and the report

- The mission goal from question 4 gives 2–3 success rules. All met = MISSION SUCCESS.
- Any meter the player sees go red can also fail the mission.
- The report lists findings: what went wrong and which Stage 1 choice caused it.
- A score out of 1000: goal rules, science returned, budget left, and timing accuracy.
- Show a predicted score on the build screen. It updates live.
- The report has three buttons: **Retry from checkpoint**, **Same design / new destination**, **Start fresh**.

## 9. Characters = play levels

The character sets the difficulty. It changes numbers only, not the rules. The premise is the same for all three: the general puts this person in charge.

| Level | Character | Changes | What the inner voice knows |
|---|---|---|---|
| Easy | Scientist | Wide timing windows, full hints, bigger budget | An expert |
| Medium | Janitor | All multipliers 1.0 (the real mission limits) | An everyday adult |
| Hard | Student | Tight windows, few hints, smaller budget | A kid |

The inner voice is never wrong. It only knows what its character knows, and it always teaches. The multipliers live in `data/levels.json`.

Multiplayer (crew roles, versus a robot) is out of scope for now. When it comes, every player uses the same character type. See section 14.

## 10. Student-made content

Each student can add content that is theirs, with no code. A content pack is one folder: `content/<student_name>/`.

A pack can hold any of these:
- `destination.json`: a new place to go
- `parts.json`: new part versions
- `events.json`: new flight or surface events
- `mission.json`: a new mission goal
- `inner_voice.json` and `story.json`: text for the new content, in the same shape as the base files

The game loads every pack in `content/` at start. A pack with an error is skipped and named in a warning. Write a one-page guide and one example pack.

## 11. Data files

Numbers go in the data files below. On-screen text stays in `story.json`, and inner-voice lines in `inner_voice.json`.

| File | Holds |
|---|---|
| `data/game_data.json` | The existing parts, mission limits, events and settings, until they move to the files below |
| `data/destinations.json` | Distance, sunlight, signal delay, trip days, arrival type, crew or no crew, materials, allowed parts |
| `data/parts.json` | Every slot and version, with `allowed_at` |
| `data/events.json` | Flight and surface events: station, timer, fix, cost |
| `data/supplies.json` | Crew supplies (food, water, air): NASA use per person per day, crew size, start amount per part |
| `data/timing.json` | Timed-press sequences and the window sizes |
| `data/levels.json` | Level multipliers: timing window, supply use per day, budget, hint detail |

Every value has `"source"` with a link, or `"PLACEHOLDER"`.

## 12. Shared systems (build once, use everywhere)

**12a. Timed press.** One reusable scene. A ring closes on a target. The player presses the key when it lines up. It returns Perfect, Good, or Miss. Inputs: label, speed, window size, key. The key is **Space** in Launch (the player cannot move) and **E** on the ship and the surface (Space is jump there). It also works with a mouse click or a tap. Used in launch, flight tasks, orbit burn, landing, science passes, and flyby.

**12b. Checkpoints.** Three checkpoints: after Build, after Launch, after Flight. Save the whole game state as one dictionary at each checkpoint. "Retry from checkpoint" on the report. It must work in the web build.

**12c. Game state.** One autoload script holds: name, level, destination, goal, launch vehicle, parts, the six resources, crew supplies (food, water, air), damage, timing results, findings. Every stage reads and writes it. No stage keeps its own copy.

**12d. Stage manager.** One script moves the player between the four stages and loads the right arrival type.

**12e. Event runner.** Reads `events.json` and runs events in the ship and on the surface.

**12f. Content loader.** Loads the base data, then every content pack.

## 13. Build order

One phase at a time. Each batch of steps ends with one full playthrough, a web export, and a browser test.

**Phase A: Skeleton, start to finish (Mars orbit only).**
Goal: a player can go from Title to Report through all four stages. Everything is gray and simple.
1. Game state autoload and stage manager (12c, 12d)
2. Setup questions 1–5, plain screens
3. Timed-press scene (12a)
4. Stage 2 Launch: sequence with 3 timed presses
5. Stage 3 Flight: Life Support room, crew supply meters, 1 leg, 2 routine tasks + 1 flight event
6. Stage 4 Arrival, orbit type: burn + the existing shadow pass and Reroute Power + 1 science pass
7. Connect Build → Launch → Flight → Arrival
8. Checkpoints 1, 2, and 3 (12b), and the three report buttons
9. Report reads the full game state

**Phase B: Surface and flyby skeletons.**
1. Destination data file and the destination question
2. Landing sequence (timed-press chain)
3. Surface area graybox with 1 material and 1 task, for Jezero only
4. Flyby type for Europa, timed presses only
5. Per-destination part lists

**Phase C: Fill in.**
1. Remaining Mars sites, from data
2. All part slots and versions
3. Three legs per flight with all crew supplies and their tasks; three tasks per site
4. Characters as levels
5. Score and predicted score
6. Content loader and the example pack

**Phase D: Real data.** Replace every PLACEHOLDER. Then one balance pass.

**Phase E: Tweaks and polish.** Only now: visuals, sound, wording, 3D models, difficulty tuning.

## 14. Out of scope for now

- Multiplayer, crew roles, versus-robot, online play
- A part-by-part rocket builder with stages
- Contracts, money over time, research trees
- Real orbital physics. Timed presses stand in for it.
- More than five destinations

## 15. Choices (2026-11-10)

1. Levels: Scientist = easy, Janitor = medium (1.0), Student = hard. No Assistant. (Kaleb, C1)
2. The five destinations. (DEFAULT, used)
3. A 3-option launch vehicle is the skeleton's "design the rocket" step. (As written; Kaleb's C8 answer: it sets the launch sequence and its cost, not the limits.)
4. A failed stage does not end the mission. The player goes on with damage. (DEFAULT, used.) Any meter that goes red can fail the mission at the report, and the report offers "Retry from checkpoint". (Kaleb, C7)
5. Mars missions have a crew on a ship that carries the player's spacecraft. Europa has no crew. (Kaleb, C5)
