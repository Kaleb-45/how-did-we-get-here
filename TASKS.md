# TASKS.md: steps left to finish "How Did We Get Here?"

Rewritten 2026-11-10 from `GAME_PLAN.md` section 13 (Phase A), after Kaleb's answers
to the conflict list C1–C16. Submission is Nov 14–15.

- **Size:** S = under 30 min, M = 30 min to 2 hours. No step is L.
- Each step can be built and tested alone. Tick the box when Kaleb says pass.
- Phase A is Mars orbit only. Everything stays gray and plain. No polish.
- The headings below are the **batches** (Kaleb, Q3, 2026-11-10). Each batch ends with one full
  playthrough (a losing and a winning round, and every room if the layout changed),
  a re-export to `build/web`, and a browser test.
- Every new made-up number is marked `"source": "PLACEHOLDER"`.

## Phase A: Skeleton, start to finish (Mars orbit only)

### Batch 1: Game state and stage manager (GAME_PLAN 12c, 12d)

- [x] **A1. Grow GameState.** S
  Add to `GameState.gd`: player name, level, destination, goal, launch vehicle, crew
  supplies (food, water, air), damage, timing results, findings. Add `to_dict()` and
  `from_dict()` so the whole state is one dictionary (needed for checkpoints).
  Test: press Play. The Output panel prints the state dictionary once. The game
  plays exactly as before.

- [x] **A2. Stage manager.** M
  One autoload, `StageManager.gd`, with the screen order in data and `go_next()`.
  Replace the hard-coded `change_scene_to_file` calls in intro, character select,
  mission select, build, review, walk and debrief.
  Test: play one round. Every screen comes in the same order as before.

### Batch 2: Setup questions (GAME_PLAN 3)

- [x] **A3. Question 1: "What is your name?"** S
  A plain screen with a text box and Next, after the intro.
  Test: type a name, play a round, and see the name on the mission report.

- [x] **A4. Question 2: "Who are you?" with three levels.** M
  Character select shows Scientist, Janitor and Student. New `data/levels.json`
  holds the hint detail per level. Levels change guidance only; budget, timing and
  supply use are the same for everyone (Kaleb, 2026-11-10). Scientist and Student show the
  "Picture goes here" box until Kaleb adds art.
  Test: pick each character in turn. The Build budget limit reads $671M for all
  three. Each card shows its level word from story.json.

- [x] **A5. Question 3: "Where are we going?"** S
  New `data/destinations.json` with one entry, Mars orbit (orbit type, crew: yes).
  One card on a plain screen.
  Test: pick Mars orbit, and the next question appears.

- [x] **A6. Question 4: "What is the mission for?"** S
  Grow mission select: the "Map the ice on Mars" card shows its 3 success rules as
  a checklist: send home at least 4 Gb/day, keep the spacecraft working 24 months,
  communications at least 0.6 Mb/s.
  Test: the card lists the rules. The report later checks the same rules.

- [x] **A7. Question 5: "What kind of rocket?"** M
  Three launch vehicle cards. Each sets the number and tightness of launch moments
  and a cost. The middle rocket's cost is taken out of the $490M spacecraft base, so
  it keeps today's balance. The $671M and 1,031 kg limits do not change. New numbers
  are PLACEHOLDER.
  Test: pick the middle rocket, and the Build budget total is the same as today. Pick
  the cheap one, and it drops. Pick the big one, and it rises. The limits stay the same.

### Batch 3: Timed press and Launch (GAME_PLAN 12a, 6a)

- [x] **A8. Timed-press scene and test bench.** M
  One reusable scene: a ring closes on a target. It returns Perfect, Good or Miss.
  Inputs: label, speed, window size (from `data/timing.json`) and key (Space or E). It also takes a mouse click or tap.
  Test: run the test bench with F6. Press early, on time and late, and see Miss,
  Perfect and Good. Switch the key to E, and Space does nothing.

- [x] **A9. Launch screen with 3 timed presses (Space).** M
  A gray side view of the rocket and 3 moments (liftoff, stage separation, engine
  cutoff). The player cannot move. A miss adds a cost to GameState (lost fuel or
  damage, PLACEHOLDER). It always goes on.
  Test: all on time, and no losses. All missed, and three costs are listed, but the
  game still goes on.

### Batch 4: Stage 3 Flight (GAME_PLAN 6b)

Kaleb tested: pass (2026-11-12).

- [x] **A10. Life Support room.** M
  A fifth graybox room off the hallway, with a sign (from `story.json`) and spots
  for the food, water and air stations.
  Test: walk into all five rooms. The walls are solid, and the new sign reads
  "Life Support".

- [x] **A11. NASA crew supply numbers.** S
  Find NASA's per-person daily food, water and oxygen numbers. Show Kaleb a table:
  value, real number, source link. After the pass, put them in
  `data/supplies.json`. Crew size and start amounts are PLACEHOLDER.
  Test: search `supplies.json` and every per-person number has a NASA link.

- [x] **A12. Crew supply meters.** M
  A "Crew supplies" group (food, water, air) on the arm dashboard, shown only in
  Flight and Arrival. The meters drop by the real use per day. The six resources keep their names and their place.
  Test: start Flight, raise the arm with Tab, and watch the three meters fall.

- [x] **A13. Food task: ration.** S
  A food station in Life Support with a "Press E" prompt. Rationing slows the food
  drop.
  Test: ration, and food drops slower. Skip it, and it drops at the normal rate.

- [x] **A14. Air task: run the oxygen generator.** S
  An air station in Life Support with a "Press E" prompt. Running the oxygen
  generator brings the air meter back up.
  Test: run it, and air recovers. Skip it, and air keeps falling.

- [x] **A15. Flight event: water leak.** M
  One event from `data/events.json`, run in Life Support. Water drops fast until the
  player fixes the leak at the water station. It is not the shadow pass.
  Test: the leak starts, the inner voice warns, water falls fast, and pressing E at
  the water station stops it.

- [x] **A16. One flight leg.** M
  The walk scene runs in Flight mode: the two tasks and the Flight event, with no
  shadow pass. The inner voice says how many real days the leg stands for. A meter at
  zero adds a finding and a damage cost. The leg ends with a move to Arrival.
  Test: do nothing (findings added) or do everything (no findings). Both reach
  Arrival.

### Batch 5: Stage 4 Arrival, orbit type (GAME_PLAN 7)

Kaleb tested: pass (2026-11-13).

- [x] **A17. Orbit burn, then the existing shadow pass.** M
  One timed press (E) for the orbit burn. A miss adds a cost. Then the existing walk
  runs as Arrival: the mission clock (mission lifetime), the shadow pass and Reroute
  Power, unchanged.
  Test: the old win/lose tests (AGENT_SOURCE section 6, item 7) give the same
  results as before.

- [x] **A18. One science pass.** M
  Two timed presses (E): capture when the target is in view, then downlink when the
  ground station is in view. Storage, power and antenna speed limit how much data
  gets home.
  Test: with the Large antenna, more data gets home than with the Small antenna.

### Batch 6: Connect, save, report (GAME_PLAN 12b, 8)

- [x] **A19. Connect the whole order.** S
  Title → questions → Build → Review → Launch → Flight → Arrival → Report.
  Test: play from the title to the report with no skipped screen.

- [x] **A20. Checkpoints 1, 2, 3.** M
  Save the whole GameState dictionary after Build, Launch and Flight. It works in
  the web build.
  Test: reach each checkpoint and see the save line in the Output panel.

- [x] **A21. The three report buttons.** M
  Retry from checkpoint, Same design / new destination, Start fresh. In Phase A
  there is only one destination, so "new destination" returns to question 3.
  Test: fail a round. Each button goes to the right place, with the right parts
  kept or cleared.

- [x] **A22. Report reads the full game state.** M
  The name, launch timings, crew supply findings, science returned and the 3 goal
  rules. Any red meter fails the mission.
  Test: a losing round and a winning round both end on the right report.

## Phase B: Surface and flyby skeletons

### Batch 7: Phase B destinations and landing

- [x] **B1. Destination data file and the destination question.** M
  `data/destinations.json` holds all five destinations with real NASA facts (source
  links) or PLACEHOLDER. The destination screen shows all five; only built arrival
  types can be picked, the others are grey with "Coming soon". Routing by arrival type
  (orbit, surface, flyby). No crew (Europa) means no crew supplies in Flight.
  Test: Mars orbit still plays as before; the other four cards cannot be picked.

- [x] **B2. Landing sequence for surface destinations.** M
  Four timed presses with SPACE (parachute out, heat shield off, landing engine on,
  touchdown). Misses cost fuel, damage or distance (timing.json, PLACEHOLDER), shown
  on a summary and in the report. Checkpoint 3 still saves after Flight.
  Test: (until batch 8 a surface site cannot be picked, so Kaleb's final test uses
  the scripted run or batch 8's unlocked cards).

### Batch 8: Phase B surface, flyby and parts

- [x] **B3. Surface area graybox (all three Mars sites).** M
  A walkable Mars-colour area after Landing, with the lander, one sample and one
  timed-press task. A surface clock: every day costs power and supplies, and the parts
  decide the days. Collect the sample before the days run out, keeping power and
  supplies out of the red = MISSION SUCCESS on the report.
  Test: collect the sample = SUCCESS; wait until the days run out = FAILED with a finding.
- [x] **B4. Flyby for Europa.** M
  Mission control screen, four timed presses with SPACE, the real radio delay on screen.
  Send home at least the planned data = MISSION SUCCESS.
  Test: Large antenna + RTG + shield, presses on time = SUCCESS; Small antenna = FAILED.
- [x] **B5. Per-destination part lists.** M
  `allowed_at` for every part: landing parts for surface sites, RTG and radiation shield
  for Europa, solar power and antenna speed scaled by the destination. The destination
  screen unlocks all five destinations.
  Test: the Build screen shows only the right parts for Mars orbit, Jezero and Europa;
  Mars orbit plays exactly as before.

## Phase C: Fill in

### Batch 9: Phase C items 1-3 (sites from data, all part slots, three legs, three tasks)

Kaleb's standing instruction (2026-11-13): finish the game with the recommended answers.

- [x] **C1. Mars sites from data.** M
  Nothing about Jezero, Gale or Arcadia stays in the code: the fallback site comes from
  the data, and each site's differences (sample distance, power cost per day, material
  bonus, ground colours) are facts in `destinations.json`. A new site is data only.
  Test: pick Arcadia Planitia and see colder power use and the ice bonus on the surface.
- [x] **C2. All part slots and versions.** M
  Add battery, computer, thermal, propulsion, life support (crew only) and surface tools
  (surface only), each with 2-3 versions in `game_data.json`. The first version of each
  new slot is already inside the spacecraft base, so Mars orbit keeps its balance.
  The Build screen scrolls when there are many rows.
  Test: Build shows the new rows; the first version of each gives the same totals as before.
- [x] **C3a. Three flight legs.** M
  Flight plays 3 legs (crew trips). Each leg has 2-3 routine tasks (ration, oxygen
  generator, water filter, harvest the garden) and 1 event (water leak, air leak, food spoils).
  A skipped task costs part of that meter. A trip with no crew (Europa) plays 1 leg.
  Test: play 3 legs; skip tasks and see findings; do them and see none.
- [x] **C3b. Three tasks per surface site.** M
  Collect a sample, run the instrument, send the data home. All three decide MISSION SUCCESS.
  Test: do all three = SUCCESS; skip the send = FAILED with a finding.
- [x] **C3c. Three science passes in Mars orbit.** M
  GAME_PLAN section 7 asks for 3 passes: three capture and downlink windows in the 60 s walk.
  Test: the win and the loss at the shadow pass still work as before.
- [ ] **C-end. Playthrough check, web export, push.** S

### Batch 10: Phase C items 4-6 (characters as levels, score, content loader)

Kaleb's standing instruction (2026-11-13): finish the game with the recommended answers.

- [x] **C4. Characters as levels.** M
  Hint detail comes from `data/levels.json` (`hint_parts`) plus `data/inner_voice.json`
  (`dashboard_warnings`: warning, problem per level, part). Scientist hears the warning, the
  problem and the part; Janitor the warning and the problem; Student only the warning.
  Test: pick each character and see the same warning get longer or shorter.
- [x] **C5. Score out of 1000.** M
  Goal rules, science returned, budget left and timing accuracy, with weights in
  `game_data.json` "score". Shown on the report with a breakdown, and as a live predicted
  score on the Build screen.
  Test: change a part on Build and watch the predicted score move; finish a run and see the breakdown.
- [x] **C6. Content loader and the example pack.** M
  Loads the base data, then every pack in `res://content/` (and `user://content/`), merging by id.
  A bad pack is skipped with a clear message. `content/example_pack/` and `docs/STUDENT_GUIDE.md`.
  Test: the Build screen shows "Example Wing (pack)"; break the pack's JSON and the game still starts.
- [x] **C-end (Batch 10). Playthrough check, web export, push.** S
  Scripted win and lose runs: Mars orbit, Jezero and Europa at all three levels, plus an example-pack run, all pass (2026-11-13). Web re-exported. Kaleb's browser test is still to do.

## Later

The old unfinished steps, kept here until Phase C is done (unless Kaleb says so).

- [x] **10. Confirm the 2026 rules (on Nov 13).** MUST · S
  Done 2026-11-13 from the official Project Submission Guide
  (https://www.spaceappschallenge.org/resources/project-submission-guide/):
  criteria are Impact, Creativity, Validity, Relevance, Presentation. Submit before
  Sunday Nov 15, 11:59 p.m. (team owner's local time). Needs: a public link with no
  login, a 30-second video or a slide deck of at most 7 slides (English, or English
  subtitles), the NASA data used (at least one NASA resource), all other data, tools
  and code listed, and NO images, video, audio or likeness of anyone under 18.
- [ ] **10b. AI disclosure in the submission.** MUST · S
  The guide says code and data made with AI tools must be acknowledged "in
  descriptive text and metadata", and AI-made images or video need a visible
  watermark. Write the AI note for the project description and add it to the repo
  README. AI must not be used to come up with the idea (the idea is Kaleb's team's).
  Generated content must not use NASA logos, flags or mission identifiers.
  Draft done in README.md (2026-11-13). Kaleb to do: say whether the intro character
  pictures in `assets/characters/` were made with an AI image tool. If yes, they need a
  visible watermark, and the README must say so.
- [ ] **11. Public link for judges.** MUST · S
  Host the newest tested `build/web`. Where to host it is still open.
- [x] **19a. Intro cutscene greybox (war room).** NICE · M
  `scenes/cutscene_intro.tscn`: octagon room, glowing table, 5 screens, 8 named
  capsules, empty AnimationPlayer. Kaleb tested: pass (2026-11-11).
- [ ] **19b. Animate the intro cutscene.** NICE · L
  Animate the characters and camera, show Mars maps on Screen_1 to Screen_5, and
  connect the cutscene to the Intro stage. Camera and people animation, subtitles and
  fade are built (23 s, ends at the name screen). Kaleb tested: pass (2026-11-11).
  Re-directed as a polished short (27.5 s, 11 shots, code-drawn Mars map shader,
  letterbox, speaker-name subtitles). Connected to the game flow: `cutscene_intro` is
  in `stages.order` after `intro`, and the cutscene calls `go_next()` (7bb25b2).
  Waiting for Kaleb's test.
- [ ] **19c. Toy-like character scenes.** NICE · M
  `scenes/characters/character_base.tscn` plus General, Janitor, Assistant Scientist,
  Student, Commander, Staff 1-3; used in the cutscene (talk, point, head turns). Built;
  waiting for Kaleb's test.
- [ ] **19d. Art pass on the intro cutscene (docs/ART_DIRECTION.md).** NICE · L
  Bright "Space Station" palette, shared matte material library in `materials/`, key,
  fill and rim lights, colour-block clothes, window with a rocket on its pad, rounded
  subtitle panel, slower staff hide (29.3 s). Polish pass: no Commander spin, walk
  cycle, readable eyes while talking, staff shots re-framed, lighting and panel fixes.
  Web build re-exported. Waiting for Kaleb's test.
- [ ] **19e. Character design pass.** NICE · L
  Clothes and one prop per role, front-only mouth, shoulder joints, boots, blink, brows,
  expressions (surprised, worried, angry); test scene `scenes/character_lineup.tscn`;
  cutscene uses the expressions. Built, reviewed and fixed (f7ee3a7); web re-exported.
  Waiting for Kaleb's test.
- [ ] **5a. Windows in the rooms.** NICE · S
- [ ] **5b. Chosen parts outside the windows.** NICE · M
- [ ] **5c. Press E at a window to inspect the part.** NICE · S
- [ ] **6. Dashboard wall screen on the Bridge.** NICE · M
- [ ] **12. Remove leftovers** (compact dashboard, `hint_small`, ask about
  `dashboard_test`). NICE · S
- [ ] **13. Alarm sound for the shadow pass.** NICE · M
- [x] **14. One-page student guide.** NICE · S Done in Batch 10: `docs/STUDENT_GUIDE.md`.
- [ ] **15. Data station mini-game in the Science bay.** NICE · L
- [ ] **16. Comms station mini-game in the Comms room.** NICE · L
- [ ] **17. More characters and missions.** NICE · L (characters are now A4 and
  Phase C item 4)
- [ ] **18. Real 3D models for the parts.** NICE · L (now Phase E)

## Done

7a–7g real NASA data, 8 balance review, 9 full playthrough and browser test
(all 2026-11-10).
