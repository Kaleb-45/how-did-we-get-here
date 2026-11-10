# TASKS.md: steps left to finish "How Did We Get Here?"

Made 2026-11-09 from `AGENT_SOURCE.md` sections 9 and 10 and `GRAYBOX_PLAN.md`.
Submission is Nov 14–15.

- **MUST** = the game does not work, or cannot be submitted, without it.
- **NICE** = it makes the game better, but the game works and can be submitted without it.
- **Size:** S = under 30 min, M = 30 min to 2 hours, L = more than 2 hours.
- Each step can be built and tested alone. Tick the box when Kaleb says pass.

## Graybox ship (finish the plan)

- [ ] **5a. Windows in the rooms.** NICE · S
  Cut one window into the outer wall of the Power room, Science bay and Comms room.
  Window sizes and places go in `game_data.json` under `ship`.
  Test: walk into each room and see out through the window. The walls stay solid.

- [ ] **5b. Chosen parts outside the windows.** NICE · M
  Show the part version the player picked outside the right window: solar panels
  (Power room), camera (Science bay), antenna (Comms room). Remove the old spacecraft
  parked off-map at x=40 in `scenes/walk.tscn`.
  Test: pick Large solar on Build, launch, and see large panels through the Power room
  window. Try again with Small solar and see small panels.

- [ ] **5c. Press E at a window to inspect the part.** NICE · S
  A "Press E" prompt at each window. The inner voice explains that part and its
  numbers. Text goes in `inner_voice.json`.
  Test: stand at each window, press E, and read the right part's explanation.

- [ ] **6. Dashboard wall screen on the Bridge.** NICE · M
  A second copy of the dashboard on a screen on the Bridge wall. It shows the same
  live numbers as the arm dashboard.
  Test: launch, stand on the Bridge, and watch the wall screen change with the arm
  dashboard during the shadow pass.

## Real NASA data

Every value marked `"source": "PLACEHOLDER"` in `data/game_data.json` gets a real
number and a source link. Students find the data, and the agent helps put it in the
file. One step per system.

**Rule for every step 7a–7g:** before changing `game_data.json`, show Kaleb a table
with three columns: value, real number, source link. Wait for pass, then change the
file.

- [x] **7a. Power: solar panels and heater.** MUST · M
  Solar panel small, medium and large (cost, mass, power, lifetime), and the heater
  (power used, lifetime lost when off).
  Before changing the file: show the table of value, real number, source link.
  Test: search the `solar_panel` and `heater` sections for PLACEHOLDER and find none.
  On Build, the solar choices show the new numbers.

- [x] **7b. Camera: basic and high resolution.** MUST · S
  Cost, mass, power used and data for each camera.
  Before changing the file: show the table of value, real number, source link.
  Test: search the `camera` section for PLACEHOLDER and find none. On Build, the camera
  choices show the new numbers.

- [x] **7c. Communications: small and large antenna.** MUST · S
  Cost, mass, power used and communications for each antenna.
  Before changing the file: show the table of value, real number, source link.
  Test: search the `antenna` section for PLACEHOLDER and find none. On Build, the
  antenna choices show the new numbers.

- [x] **7d. Spacecraft base.** MUST · S
  The base spacecraft before any parts: budget, mass, power, lifetime.
  Before changing the file: show the table of value, real number, source link.
  Test: search `spacecraft_base` for PLACEHOLDER and find none. On Review, the totals
  include the new base numbers.

- [x] **7e. Mission limits for "Map the ice on Mars".** MUST · M
  The six limits (budget, mass, power, communications, data, mission lifetime), with
  their warning and bar_max values.
  Before changing the file: show the table of value, real number, source link.
  Test: search `missions` for PLACEHOLDER and find none. The dashboard limit markers
  sit at the new values.

- [x] **7f. Shadow pass (Mars eclipse).** MUST · S
  The spacecraft flies into Mars' shadow: the solar panels make no power and the
  batteries give 400 W, for 20 s of game time (real: 40 of every 112 minutes).
  Before changing the file: show the table of value, real number, source link.
  Test: search `events` for PLACEHOLDER and find none. Launch, and the shadow pass
  sets off the power alarm for every build.

- [x] **7g. Game timing and the janitor's difficulty.** MUST · S
  `mission_clock` (how fast months pass) and the janitor's limit multipliers. These
  are game choices, not spacecraft facts. Answered: use a NASA source where there is
  one (0.4 months/s ties the 60 s walk to MRO's 24-month science phase; 30.4 days per
  month is calendar math), and mark the rest as a written game-design choice.
  Before changing the file: show the table of value, real number, source link.
  Test: search `game_data.json` for `"source": "PLACEHOLDER"` and find none. (The word PLACEHOLDER still appears once, in the top `_readme` instruction.)

- [ ] **8. Balance review with the real numbers.** MUST · M
  Check that at least one build can win and one can fail, without making the player
  "play scared". Change limits only, with a source or a written reason. Then
  rewrite the inner-voice part lines in `data/inner_voice.json` (for example "barely
  makes enough power" for the small panel) to match the real numbers. Also the camera
  lines: the high resolution camera "eats power" (it uses 60 W, a fifth of the 300 W
  heater), and the basic camera's "blurry" pictures (CTX maps all of Mars). Also the
  large antenna is "power hungry" (both antennas now use the same 172 W).
  Test: play three different builds and see at least one success and one failure.

- [ ] **9. Full playthrough, re-export, browser test.** MUST · M
  Comes after the real numbers are in. The current `build/web` is from before the
  ship. Re-export to `build/web`. Kaleb plays a losing round and a winning round in
  the editor and in the browser, and walks through every room.
  Test: both rounds end on the right mission report, in the editor and the browser.

## Submission

- [ ] **10. Confirm the 2026 rules (on Nov 13).** MUST · S
  Read the 2026 Space Apps guide. Confirm the judging criteria names (is it
  "Influence"?) and what a submission needs (for example a video, slides, or a
  public link). Update `CLAUDE.md` and `reviewer.md`, and add any new MUST steps
  here.
  Test: `CLAUDE.md` names the confirmed criteria, with no "confirm" note.

- [ ] **11. Public link for judges.** MUST · S
  Put the step 9 build where judges can play it. If anything changed after step 9,
  re-export and test in the browser first. Where to host it is an open choice for
  Kaleb (itch.io was offered before but never picked).
  Test: open the public link on another computer and play one round.

## Polish and extras

- [ ] **12. Remove leftovers.** NICE · S
  Remove the unused compact-dashboard mode and the `"hint_small": "Tab = bigger"`
  text. Ask Kaleb before removing the `dashboard_test` bench.
  Test: play one round and see no change.

- [ ] **13. Alarm sound for the shadow pass.** NICE · M
  Made in Godot code, with no downloads, like the textures.
  Test: the alarm sounds when power goes red and stops when it is fixed.

- [ ] **14. One-page student guide.** NICE · S
  How to play, and how to change a number in `game_data.json`.
  Test: a student follows it and changes one part's cost.

- [ ] **15. Data station mini-game in the Science bay.** NICE · L
  Replaces the "Future station: Data" marker.

- [ ] **16. Comms station mini-game in the Comms room.** NICE · L
  Replaces the "Future station: Comms" marker.

- [ ] **17. More characters and missions.** NICE · L
  An easier and a harder character, using the limit multipliers, and a second mission.

- [ ] **18. Real 3D models for the parts.** NICE · L
  Fill the `"model"` slot for each part version. Ask Kaleb before downloading any model.
