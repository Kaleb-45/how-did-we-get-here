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

- [ ] **A10. Life Support room.** M
  A fifth graybox room off the hallway, with a sign (from `story.json`) and spots
  for the food, water and air stations.
  Test: walk into all five rooms. The walls are solid, and the new sign reads
  "Life Support".

- [ ] **A11. NASA crew supply numbers.** S
  Find NASA's per-person daily food, water and oxygen numbers. Show Kaleb a table:
  value, real number, source link. After the pass, put them in
  `data/supplies.json`. Crew size and start amounts are PLACEHOLDER.
  Test: search `supplies.json` and every per-person number has a NASA link.

- [ ] **A12. Crew supply meters.** M
  A "Crew supplies" group (food, water, air) on the arm dashboard, shown only in
  Flight and Arrival. The meters drop by the real use per day. The six resources keep their names and their place.
  Test: start Flight, raise the arm with Tab, and watch the three meters fall.

- [ ] **A13. Food task: ration.** S
  A food station in Life Support with a "Press E" prompt. Rationing slows the food
  drop.
  Test: ration, and food drops slower. Skip it, and it drops at the normal rate.

- [ ] **A14. Air task: run the oxygen generator.** S
  An air station in Life Support with a "Press E" prompt. Running the oxygen
  generator brings the air meter back up.
  Test: run it, and air recovers. Skip it, and air keeps falling.

- [ ] **A15. Flight event: water leak.** M
  One event from `data/events.json`, run in Life Support. Water drops fast until the
  player fixes the leak at the water station. It is not the shadow pass.
  Test: the leak starts, the inner voice warns, water falls fast, and pressing E at
  the water station stops it.

- [ ] **A16. One flight leg.** M
  The walk scene runs in Flight mode: the two tasks and the Flight event, with no
  shadow pass. The inner voice says how many real days the leg stands for. A meter at
  zero adds a finding and a damage cost. The leg ends with a move to Arrival.
  Test: do nothing (findings added) or do everything (no findings). Both reach
  Arrival.

### Batch 5: Stage 4 Arrival, orbit type (GAME_PLAN 7)

- [ ] **A17. Orbit burn, then the existing shadow pass.** M
  One timed press (E) for the orbit burn. A miss adds a cost. Then the existing walk
  runs as Arrival: the mission clock (mission lifetime), the shadow pass and Reroute
  Power, unchanged.
  Test: the old win/lose tests (AGENT_SOURCE section 6, item 7) give the same
  results as before.

- [ ] **A18. One science pass.** M
  Two timed presses (E): capture when the target is in view, then downlink when the
  ground station is in view. Storage, power and antenna speed limit how much data
  gets home.
  Test: with the Large antenna, more data gets home than with the Small antenna.

### Batch 6: Connect, save, report (GAME_PLAN 12b, 8)

- [ ] **A19. Connect the whole order.** S
  Title → questions → Build → Review → Launch → Flight → Arrival → Report.
  Test: play from the title to the report with no skipped screen.

- [ ] **A20. Checkpoints 1, 2, 3.** M
  Save the whole GameState dictionary after Build, Launch and Flight. It works in
  the web build.
  Test: reach each checkpoint and see the save line in the Output panel.

- [ ] **A21. The three report buttons.** M
  Retry from checkpoint, Same design / new destination, Start fresh. In Phase A
  there is only one destination, so "new destination" returns to question 3.
  Test: fail a round. Each button goes to the right place, with the right parts
  kept or cleared.

- [ ] **A22. Report reads the full game state.** M
  The name, launch timings, crew supply findings, science returned and the 3 goal
  rules. Any red meter fails the mission.
  Test: a losing round and a winning round both end on the right report.

## Later

The old unfinished steps, kept here until Phase C is done (unless Kaleb says so).

- [ ] **10. Confirm the 2026 rules (on Nov 13).** MUST · S
  Read the 2026 Space Apps guide. Confirm the judging criteria names and what a
  submission needs. Update `CLAUDE.md` and `reviewer.md`.
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
- [ ] **5a. Windows in the rooms.** NICE · S
- [ ] **5b. Chosen parts outside the windows.** NICE · M
- [ ] **5c. Press E at a window to inspect the part.** NICE · S
- [ ] **6. Dashboard wall screen on the Bridge.** NICE · M
- [ ] **12. Remove leftovers** (compact dashboard, `hint_small`, ask about
  `dashboard_test`). NICE · S
- [ ] **13. Alarm sound for the shadow pass.** NICE · M
- [ ] **14. One-page student guide.** NICE · S (GAME_PLAN 10 asks for a content-pack
  guide in Phase C.)
- [ ] **15. Data station mini-game in the Science bay.** NICE · L
- [ ] **16. Comms station mini-game in the Comms room.** NICE · L
- [ ] **17. More characters and missions.** NICE · L (characters are now A4 and
  Phase C item 4)
- [ ] **18. Real 3D models for the parts.** NICE · L (now Phase E)

## Done

7a–7g real NASA data, 8 balance review, 9 full playthrough and browser test
(all 2026-11-10).
