# TASKS.md: steps left to finish "How Did We Get Here?"

Rewritten 2026-11-10 from `GAME_PLAN.md` section 13 (Phase A), after Kaleb's answers
to the conflict list C1–C16. Submission is Nov 14–15.

- **Size:** S = under 30 min, M = 30 min to 2 hours. No step is L.
- Each step can be built and tested alone. Tick the box when Kaleb says pass.
- **BLOCKED (Q#)** = waits for Kaleb's answer to open question Q# (2026-11-10 report).
- Phase A is Mars orbit only. Everything stays gray and plain. No polish.
- The headings below are suggested **batches**. Each batch ends with one full
  playthrough (a losing and a winning round, and every room if the layout changed),
  a re-export to `build/web`, and a browser test.
- Every new made-up number is marked `"source": "PLACEHOLDER"`.

## Phase A: Skeleton, start to finish (Mars orbit only)

### Batch 1: Game state and stage manager (GAME_PLAN 12c, 12d)

- [ ] **A1. Grow GameState.** S
  Add to `GameState.gd`: player name, level, destination, goal, launch vehicle, crew
  supplies (food, water, air), damage, timing results, findings. Add `to_dict()` and
  `from_dict()` so the whole state is one dictionary (needed for checkpoints).
  Test: press Play. The Output panel prints the state dictionary once. The game
  plays exactly as before.

- [ ] **A2. Stage manager.** M
  One autoload, `StageManager.gd`, with the screen order in data and `go_next()`.
  Replace the hard-coded `change_scene_to_file` calls in intro, character select,
  mission select, build, review, walk and debrief.
  Test: play one round. Every screen comes in the same order as before.

### Batch 2: Setup questions (GAME_PLAN 3)

- [ ] **A3. Question 1: "What is your name?"** S
  A plain screen with a text box and Next, after the intro.
  Test: type a name, play a round, and see the name on the mission report.

- [ ] **A4. Question 2: "Who are you?" with three levels.** M
  Character select shows Scientist, Janitor and Student. New `data/levels.json`
  holds the multiplier table (PLACEHOLDER until Kaleb passes it). The budget
  multiplier works now through the existing limit math. Timing, supply and hint
  multipliers are stored now and used by later steps. Scientist and Student show the
  "Picture goes here" box until Kaleb adds art.
  Test: pick each character in turn. The Build budget limit reads $738M, $671M,
  $637M.

- [ ] **A5. Question 3: "Where are we going?"** S
  New `data/destinations.json` with one entry, Mars orbit (orbit type, crew: yes).
  One card on a plain screen.
  Test: pick Mars orbit, and the next question appears.

- [ ] **A6. Question 4: "What is the mission for?"** S · BLOCKED (Q4)
  Grow mission select: the "Map the ice on Mars" card shows its 2–3 success rules
  as a checklist.
  Test: the card lists the rules. The report later checks the same rules.

- [ ] **A7. Question 5: "What kind of rocket?"** M · BLOCKED (Q1)
  Three launch vehicle cards. Each sets the number and tightness of launch moments
  and a cost. The $671M and 1,031 kg limits do not change. New numbers are
  PLACEHOLDER.
  Test: pick each rocket. The limits stay the same, and the cost line changes.

### Batch 3: Timed press and Launch (GAME_PLAN 12a, 6a)

- [ ] **A8. Timed-press scene and test bench.** M
  One reusable scene: a ring closes on a target. It returns Perfect, Good or Miss.
  Inputs: label, speed, window size (from `data/timing.json`, times the level's
  timing multiplier) and key (Space or E). It also takes a mouse click or tap.
  Test: run the test bench with F6. Press early, on time and late, and see Miss,
  Perfect and Good. Switch the key to E, and Space does nothing.

- [ ] **A9. Launch screen with 3 timed presses (Space).** M
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
  Flight and Arrival. The meters drop by use per day times the level's supply
  multiplier. The six resources keep their names and their place.
  Test: start Flight, raise the arm with Tab, and watch the three meters fall.

- [ ] **A13. Routine task 1.** S · BLOCKED (Q2)
  A Life Support station with a "Press E" prompt and one action.
  Test: do the task, and its meter drops slower. Skip it, and it drops faster.

- [ ] **A14. Routine task 2.** S · BLOCKED (Q2)
  Same as A13, for the second task.
  Test: the same as A13.

- [ ] **A15. One Flight event.** M · BLOCKED (Q2)
  One event from `data/events.json`, run in the ship. It is not the shadow pass.
  Test: the event starts, the inner voice warns, and fixing it at the right station
  stops it.

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

- [ ] **A22. Report reads the full game state.** M · BLOCKED (Q4)
  The name, launch timings, crew supply findings, science returned and the goal
  rules. Any red meter fails the mission.
  Test: a losing round and a winning round both end on the right report.

## Later

The old unfinished steps, kept here until Phase C is done (unless Kaleb says so).

- [ ] **10. Confirm the 2026 rules (on Nov 13).** MUST · S
  Read the 2026 Space Apps guide. Confirm the judging criteria names and what a
  submission needs. Update `CLAUDE.md` and `reviewer.md`.
- [ ] **11. Public link for judges.** MUST · S
  Host the newest tested `build/web`. Where to host it is still open.
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
