# AGENT_SOURCE.md: How Kaleb builds games with Claude Code

Source material for agents that build games the way Kaleb does. It was extracted on 2026-11-09 from:

- **The codebase:** `how-did-we-get-here/`, at commit `2e7a732`.
- **The git history:** one commit, "Graybox ship interior, steps 1-4: hallway, four rooms, signs, power panel", made 2026-11-09.
- **CLAUDE.md:** this folder had none at extraction time. One was added later on 2026-11-09 (commit `06ab0c1`). It holds the short rules every agent follows.
- **Session transcripts.** This folder's transcript folder (`~/.claude/projects/-Users-kalebtovar-Desktop-Nasa-Space-App-Challenge-how-did-we-get-here/`) holds only one file, and it is this extraction session. The game was really built in sessions started from the **Motion Studio** folder (`~/.claude/projects/-Users-kalebtovar-Desktop-OCAI-Center-Content-Creation--Motion-Studio/`):
  - `b4bfa5db-57ad-4afb-b944-c2c1c401ddfc.jsonl` is the whole build: 2026-11-08 to 2026-11-09, about 50 user turns and 3 context compactions.
  - `7ecfb294-1005-46f8-822d-0aea10f68608.jsonl` only holds a `cd` into this folder, with no game work.

Dates are local Pacific time, the same zone as the commit.

---

## 1. Game summary

- **Title:** "How Did We Get Here?" (`project.godot`: "How did we get here").
- **What it is:** a proof-of-concept mission-design game made in Godot 4.
  - The chief mission designer quits suddenly, and the general puts a random person in charge: the janitor.
  - The player must plan a real NASA-style science mission, "Map the ice on Mars", with no training.
  - An **inner voice** in the player's head guides them, warns them and explains failures.
- **The core loop:**
  1. Intro.
  2. Pick a character (only the janitor, medium difficulty).
  3. Pick a mission (one).
  4. Build: choose a version of the solar panel, camera and antenna.
  5. Review the six resources (budget, mass, power, communications, data, mission lifetime) against the mission limits.
  6. Launch into a **first-person 3D walk** through the ship. A wrist light and a raisable arm dashboard show live resources.
  7. A **Mars shadow pass** (the orbiter flies through Mars' shadow) cuts solar power to zero, and the batteries cannot carry everything. The player runs the **Reroute Power** mini-game at the power panel.
  8. The **mission report** debrief shows success or failure. Each failure lists what failed, why it failed and how to fix it.
  9. Try again.
- **Who plays it:**
  - Students **aged 10–15** ("Students aged 10–15 will play this." 2026-11-08).
  - It is built by Kaleb, a Magikid coach, for "a team of 5 Magikid students" as a demo "so the students can see how the game works before they build the real one" (2026-11-08).
- **The challenge it answers:** NASA Space Apps Challenge 2026 (Nov 14–15), challenge **"Space Mission Design Game"** (2026-11-08).
- **From 2026-11-10 the game grows into the full game in `GAME_PLAN.md`:** setup questions, Build, Launch, Flight, Arrival and the report, for five destinations. The summary above is the proof of concept it grows from.

---

## 2. Design decisions

### Player experience
- **In the intro cutscene (mission control war room), the Assistant Scientist, the Janitor and the Student are the three playable characters.** The Assistant Scientist capsule is the playable scientist (easy). Not a non-playing extra.
  Why: "assistant is a play able character, so is janitor and the student." (2026-11-11)
- **The general puts a person in charge: a scientist, the janitor or a student. The premise is the same for all three.** Later, in multiplayer, every player uses the same character type.
  Why: "The premise for all: the general puts this person in charge. Later, in multiplayer, every player uses the same character type." (2026-11-10) The original premise: "The player must plan a real NASA-style science mission with no training." (2026-11-08)
- **An inner voice guides, warns and explains failures. It is the game's only teacher.**
  Why: Kaleb's brief (2026-11-08).
- **The inner voice is never wrong. It only knows what its character knows (scientist = expert, janitor = everyday adult, student = kid), and it always teaches.**
  Why: "The voice is never wrong. It only knows what its character knows... and it always teaches." (2026-11-10)
- **Six resources with exact names: budget, mass, power, communications, data, mission lifetime.**
  Why: "Use these exact names" (2026-11-08). Kept: "Keep the six exact resource names." (2026-11-10)
- **Mission lifetime means how long the spacecraft works after arrival.**
  Why: "Mission lifetime = how long the spacecraft works after arrival." (2026-11-10)
- **Food, water and air are a separate group, "crew supplies", shown in Flight and Arrival only.**
  Why: "Food, water, and air are a separate group: 'crew supplies', shown in Flight and Arrival only." (2026-11-10)
- **Mars missions have a crew on a ship that carries the spacecraft the player built. Europa has no crew. Crew supplies use NASA's real per-person daily food, water and oxygen numbers, with source links.**
  Why: "Mars missions have a crew on a ship that carries the spacecraft the player built. Use NASA's real per-person daily food, water, and oxygen numbers, with source links. Europa has no crew." (2026-11-10)
- **One heat mechanic only: the heater switch on the power panel. No heat meter, no thermal-panel task.**
  Why: "One heat mechanic only: the heater switch on the power panel." (2026-11-10)
- **The mission limits stay real: budget max $671M, mass max 1,031 kg. The launch vehicle changes the launch sequence and its cost, not these limits.**
  Why: "Keep the real limits... The launch vehicle changes the launch sequence and its cost, not these limits." (2026-11-10)
- **Three levels: Scientist = easy, Janitor = medium, Student = hard. The levels change only how much guidance the player gets. Budget, mass, timing windows and supply use are the same for everyone (the real numbers).**
  Why: "3 levels, not 4... Drop 'Assistant'." (2026-11-10) and "the budget should be the same or everyone, the different levels will just be how much guidance we give them." Kaleb then picked "guidance only": timing windows and supply use are the same for all levels too (2026-11-10).
- **Hint detail per level:** Scientist = full (names the problem and the part that causes it), Janitor = some (names the problem), Student = few (only the warning). Hints never give the answer.
  Why: accepted with "for all questions do recommended" (2026-11-10), and kept when the other multipliers were dropped.
- **After each setup answer, the inner voice reacts and a Next button appears. The player reads at their own pace.**
  Why: Kaleb picked "Show a Next button (Recommended)" over a timer (2026-11-10).
- **The rocket's cost comes out of the spacecraft base budget: the middle rocket's cost is taken out of the $490M base, so the middle rocket keeps today's balance and the other two move it up or down.** MAVEN's $671M and MRO's $720M already include their launch.
  Why: "for all questions do recommended" (Q1, 2026-11-10).
- **Phase A Flight: two routine tasks, food (ration) and air (run the oxygen generator, like the real one on the Space Station), and one event, a water leak, all in the Life Support room.**
  Why: "for all questions do recommended" (Q2, 2026-11-10). The air task was changed from "swap the scrubber" because a real scrubber removes carbon dioxide and makes no oxygen; Kaleb picked "Run the oxygen generator (Recommended)" (2026-11-10).
- **In Arrival, the crew uses NASA's real daily amounts for all 730 days of the mission clock. Start amounts grow to match.**
  Why: Kaleb picked "Use the real 730 days (Recommended)" over sending the crew home at 90 days (2026-11-10).
- **"Map the ice on Mars" has 3 goal rules, all from numbers already passed: send home at least 4 Gb/day, keep the spacecraft working 24 months, communications at least 0.6 Mb/s.**
  Why: "for all questions do recommended" (Q4, 2026-11-10).
- **Limits must matter, so the player cannot take everything. But they must not be so tight that the player plays scared. The player should be able to take risks and "do some damage."**
  Why: Kaleb's own words (2026-11-09).
- **Each resource has three colors: green = safe, yellow = close to the limit, red = past a max or under a min.**
  Why: Kaleb's dashboard brief (2026-11-08).
- **Rows still red at the end of the walk count as mission failures. Any meter the player sees go red can fail the mission, in every stage. On fail, the report offers "Retry from checkpoint".**
  Why: "yes we can count it as failure, they should have goals that will make it so that they need to pay attention to what they need to do" (2026-11-08). "AGENT_SOURCE wins. Any meter the player sees go red can fail the mission. On fail, offer 'Retry from checkpoint'." (2026-11-10)
- **The report has three buttons: Retry from checkpoint, Same design / new destination, Start fresh.**
  Why: Kaleb's C15 answer (2026-11-10).
- **The wrist light shows the worst row (green, yellow or red) and blinks on red. The dashboard stays hidden until Tab raises the arm.**
  Why: "an arm that will have a light on it that will go red if something goes bad... That way its hidden but also still can notify if anything is wrong." (2026-11-08)
  Picked options: "Light warns, Tab raises arm" and "Green / yellow / red".
- **When the arm is raised, the dashboard is a 2D screen panel above the wrist, not a 3D wrist screen.**
  Why: Kaleb picked the recommended option, "Easy to read, reuses the dashboard we already built." (2026-11-08)
- **The live event is a Mars shadow pass.**
  - At 20 s the orbiter enters Mars' shadow for 20 s. Solar power drops 100% (real), and batteries give 400 W (game-design choice; the real MRO batteries could give about 1,900 W, written in the source).
  - Every build sets off the alarm. The player gets 15 s to fix it, by turning off the antenna OR the heater. This matches NASA's real fix: MRO turns heaters down before it enters shadow.
  - The 20 s shadow stands for every real 40-minute shadow, sped up, and the inner voice says so.
  - Why: Kaleb picked option B, "Mars shadow pass with 400 W batteries", and said "pass" to the recommendations (2026-11-10). A real dust storm barely dims an orbiter, so the old event was weak on Validity. The 15 s countdown is shorter than the 20 s shadow because otherwise "a player who does nothing would be saved when the storm ends" (data `_readme`, 2026-11-09).
  - **It is a Mars-orbit event only. It lives in Stage 4 Arrival (orbit type) and keeps its win/lose tests. Flight gets other events.**
    Why: "The shadow pass stays a Mars-orbit event. Move it to Stage 4 Arrival (orbit type). Keep its win/lose tests. Flight gets other events." (2026-11-10)
- **Reroute Power mini-game: at a power panel, switch the camera, antenna and heater on or off until the power used fits the power available. Systems can be turned back on after the shadow pass.**
  Why: Kaleb's brief (2026-11-09).
- **Turning a system off has a cost.**
  - No camera means no data.
  - No antenna means no communications.
  - No heater means mission lifetime drops faster: 1 month per 5 s.
  - Why: "Turning a system off has a cost... The dashboard shows this live." (2026-11-09) I proposed the heater cost, and Kaleb accepted it with "pass" (2026-11-09).
- **The mission ends when the mission clock reaches the mission length (24 months, about 60 s of real time).**
  Why: my R1 suggestion, accepted with "pass" (2026-11-09).
- **Controls:**
  - WASD to walk, Space to jump, mouse to look, E to use.
  - Tab raises the arm (dashboard).
  - Esc frees the mouse. Esc or E closes a panel.
  - Why: "can we get a jump feature please" (2026-11-08). The rest is the brief and the arm feature.
- **Timed presses: Space only in Launch, where the player cannot move. On the ship and the surface, timed presses use E, and Space stays jump.**
  Why: "Space = jump on the ship. Space = timed press only in Launch, where the player cannot move. Timed presses on the ship or surface use E." (2026-11-10)
- **"Press E" prompts appear near interactive things: parts, the power panel and, later, parts seen at windows.**
  Why: the brief: "When the player walks close to a part and presses E, the inner voice explains that part and its numbers." (2026-11-08) Inspecting parts at the windows was accepted at G1 (2026-11-09).

### Game structure
- **Arrival (orbit type) = an Orbit burn screen between Flight and the Arrival walk (one timed press with E; a miss costs 15% fuel, PLACEHOLDER, stored like Launch costs), then the walk, shadow pass and Reroute Power unchanged.**
  Why: Kaleb picked "all recommended" for Batch 5 (2026-11-12).
- **One science pass inside the Arrival walk: capture with E at the Science bay while the target is in view (4-16 s), downlink with E at the Comms room while the ground station is in view (44-58 s), shown by a calm banner with a countdown and the station label. Data sent home is limited by a fixed storage size (PLACEHOLDER), the camera and antenna switches (off = nothing), and the real antenna speed. Science sent home does not change the report or MISSION SUCCESS yet (A22 adds it to the report). Levels do not change the burn or the science pass yet. One pass now; three passes wait for Phase C.**
  Why: Kaleb picked "all recommended" for Batch 5 (2026-11-12).
- **Screen flow (GAME_PLAN.md section 2): Title → setup questions 1–5 → Build → Review → Checkpoint 1 → Launch → Checkpoint 2 → Flight → Checkpoint 3 → Arrival → Report.**
  Why: "GAME_PLAN.md is the design source. Build in its phase order." (2026-11-10)
- **The full game has five destinations (Mars orbit, Jezero, Gale, Arcadia Planitia, Europa).**
  Why: "Full 5-destination game." (2026-11-10)
- **I built the 2D loop (Build → Review → Debrief) before the 3D walk.**
  Why: my plan, so "the students can play a whole working loop early, and the 3D walk slots into the middle later" (2026-11-08). Kaleb approved it.
- **Two autoloads hold the logic: `Data` loads the JSON files, and `GameState` holds the choices and does all the math. A third autoload, `Textures`, makes textures in code.**
  Why: this follows from the data rules (2026-11-08) (guess: Kaleb did not phrase it this way).
- **The dashboard is one reusable scene. It only draws values and does no math. It is used on Build, in the walk (on the arm) and later on the Bridge wall.**
  Why: "One reusable dashboard scene" (2026-11-08).
- **The 3D walk takes place in a graybox ship interior: one hallway plus five rooms: Bridge (start), Power room, Science bay, Comms room and Life Support (food, water, air). The old hangar is archived.**
  Why: Kaleb's brief (2026-11-09). Archiving the hangar was accepted at G1. "Add one room: Life Support (food, water, air). Five rooms total." (2026-11-10)
- **The Reroute Power station lives in the Power room and "must work exactly as it does now."**
  Why: Kaleb's brief (2026-11-09).
- **The Science bay and Comms room stations are the science pass stations: capture at the Science bay, downlink at the Comms room, in the Arrival walk only. In Flight their labels say they work in Mars orbit.**
  Why: Kaleb picked "all recommended" for Batch 5 (2026-11-12).
- **Difficulty is set by how much guidance the character gets, not by changing the numbers.**
  Why: the brief named "janitor (medium difficulty)" (2026-11-08). "the budget should be the same or everyone, the different levels will just be how much guidance we give them." Kaleb then picked "guidance only": timing windows and supply use are the same for all levels too (2026-11-10).
- **When `GAME_PLAN.md` gives a DEFAULT, agents use it and list it in the report. Otherwise they ask one short question.**
  Why: "Use the GAME_PLAN DEFAULTs and list them in your report." (2026-11-10)
- **The playthrough, web export and browser test happen once per batch of steps. A batch is one of the batch headings in `TASKS.md`; a single step is not its own batch.**
  Why: "One playthrough, web export, and browser test per batch of steps." and "for all questions do recommended" (Q3, 2026-11-10).

### NASA data
- **No numbers are hard-coded in scripts. Numbers go in the data files listed in `GAME_PLAN.md` section 11: `game_data.json`, `destinations.json`, `parts.json`, `events.json`, `supplies.json`, `timing.json`, `levels.json`. On-screen text stays in `story.json` and inner-voice text in `inner_voice.json`.**
  Why: Kaleb's data rule (2026-11-08). "Use the GAME_PLAN data files... Text stays in story.json and inner_voice.json." (2026-11-10)
- **Placeholder numbers are marked `"source": "PLACEHOLDER"`.**
  Why: "Use placeholder numbers for now and mark them as placeholders. A student will replace them later with real NASA data." (2026-11-08)
- **Each number's `source` must be replaced with a link or document name when real data goes in.**
  Why: the `_readme` in `game_data.json` (2026-11-08).
- **The agent finds real NASA numbers by web search (no downloads), and cites a source link for each one.**
  Why: Kaleb picked "Agent searches the web (Recommended)" (2026-11-09).
- **Each game part version stands for real flown NASA hardware and uses its published mass and power. Where no cost is published, the source says "no public source" and the game value stays.**
  Why: Kaleb picked "Match a real mission (Recommended)" (2026-11-09).
- **For a batch of data steps, show all the tables (value, real number, source link) together, wait for one pass, then build them in a row.**
  Why: Kaleb picked "All 3 tables first (Recommended)" (2026-11-09).
- **Real hardware for the parts: small solar = Mars Odyssey array, medium = MAVEN arrays, large = MRO arrays (both wings, 96.6 kg), basic camera = MRO CTX, high-res camera = MRO HiRISE, small antenna = Mars Odyssey 1.3 m high-gain antenna, large antenna = MRO 3 m high-gain antenna, heater = all MRO heaters.**
  Why: "pass" on the 7a–7c tables, accepting the recommended answers (2026-11-10).
- **Crew supplies per person per day: food 1.831 kg (with packaging; Lopez et al., NASA JSC, NTRS 20150003005, "BVAD Table & ISS experience"), water 2.5 L (NASA-STD-3001 OCHMO-TB-027, minimum potable water for hydration), oxygen 0.82 kg (Lopez et al., "O 2 Metabolic ... HIDH / BVAD"). Crew size, start amounts, task effects and the leak rate stay PLACEHOLDER.** The ECLSS brief's 1.083 kg/day oxygen (with 2 h exercise) was offered and not picked.
  Why: "pass" on the A11 table (2026-11-10).
- **Every number comes from a NASA source. News sources do not count: where NASA has no number (for example HiRISE cost), write "no public source" and keep the game value.**
  Why: "pass", accepting the recommendation (2026-11-10).
- **A peer-reviewed science paper by the NASA instrument team counts as a source when no NASA page has the number (for example HiRISE data per day, McEwen et al. 2007). News sources still do not count.**
  Why: Kaleb passed the 7b table with this paper as the source (2026-11-10).
- **Both antennas use the same 172 W radio amplifier power (as on MRO). The real difference between them is size and data rate.**
  Why: "pass", accepting the recommendation (2026-11-10).
- **Values with no real-world match (solar lifetime bonus, heater lifetime loss) are marked as a written game-design choice instead of a source link.**
  Why: "pass", accepting the recommendation (2026-11-10). This also answers step 7g.
- **"Gb/day" means gigabits per day.**
  Why: "pass", accepting the recommendation (2026-11-10).
- **The spacecraft base is MRO without the swappable parts, so the biggest build (Large solar, High-res, Large antenna) is the real MRO. The base keeps the CTX camera.**
  Why: "pass" on the 7d/7e tables, accepting the recommendations (2026-11-10).
- **The mission budget limit is MAVEN's real total cost ($671M), so "you built MRO, with MAVEN money" fails. The player cannot take everything.**
  Why: "pass", accepting the recommendation (2026-11-10).
- **The comms minimum is MRO's real rate at its farthest from Earth (0.6 Mb/s), so the small antenna always fails comms. This is a real-world lesson.**
  Why: "pass", accepting the recommendation (2026-11-10).
- **Base mission lifetime is 30 months (game-design choice), so Small solar can still win. Data minimum 4 Gb/day is a game-design choice. Mass limit is MRO's real dry mass (1,031 kg), so mass only turns yellow and never fails alone.**
  Why: "pass", accepting the recommendations (2026-11-10).
- **NASA's own news pages (jpl.nasa.gov, science.nasa.gov) count as sources. Outside news does not.**
  Why: "pass" on the 7f/7g choices, accepting the recommendation (2026-11-10).
- **Where two NASA pages disagree, keep the number already passed and write the other one in the source text** (for example MRO solar power: 2,000 W in the press kit, 1,000 W on an archived JPL page).
  Why: "pass", accepting the recommendation (2026-11-10).
- **Game balance is decided only after real numbers arrive.** With the placeholder numbers, "Medium solar + Basic camera always fails. That could be a good lesson or too harsh for 10–15 year olds; worth deciding once you have real NASA numbers." (my note, 2026-11-09). Settled 2026-11-10 in step 8: with real numbers, 4 builds can win and doing nothing always loses. See the step 8 lines below.
- **Keep the Large solar panel as it is, even though Medium does the same job for less in this mission. Its voice line teaches why: in Mars' shadow it makes no power.**
  Why: Kaleb passed the step 8 balance review (2026-11-10).
- **Keep turning the antenna off as a cheap fix (communications only count at the end), until the Comms station gives it a cost.**
  Why: Kaleb passed the step 8 balance review (2026-11-10).
- **Keep the failure cards that the janitor cannot reach (the mass, power, data and mission lifetime build cards, and the `storm_ok` line). Students who change numbers, or a harder character, will reach them.**
  Why: Kaleb passed the step 8 balance review (2026-11-10).
- **Keep the "just fits" case: High-res camera with the antenna off leaves exactly 0 W spare in the shadow, and that counts as fitting.**
  Why: Kaleb passed the step 8 balance review (2026-11-10).
- **No change to the Small solar heater timing: the heater can be off 30 s at most in total (for example, off at 22 s, back on by 52 s).**
  Why: Kaleb passed the step 8 balance review (2026-11-10).

### Visual style
- **The 3D starts as simple boxes and cylinders, with an optional `"model"` path per part version to swap in real models later.**
  Why: "yea, lets just build it for now then upgrade" (2026-11-08).
- **Textures are made in Godot code, with no downloads.**
  Why: Kaleb picked "Made in Godot, no downloads" (2026-11-08).
- **The ship interior is a graybox: plain boxes, no art.**
  Why: Kaleb's brief, "A graybox is a rough layout with plain boxes, no art." (2026-11-09)
- **All 2D screens use a navy and orange theme from one shared theme file (`theme/game_theme.tres`).**
  Why: "Use a navy and orange color theme on all 2D screens (intro, build, review, debrief)." (2026-11-08)
- **Text is large everywhere: base font 26, titles 50, body 28, smallest 22–24.**
  Why: "Make all text larger and easier to read. Students aged 10–15 will play this." (2026-11-08)
- **The walk's control hints at the top are large.**
  Why: "The control hints at the top of the walk screen are too small to read. Make them larger." (2026-11-08)
- **Characters are cute, rounded, toy-like, made only from built-in shapes and the shared materials: one rounded body with no neck, arms attached at shoulder joints, short legs with two small rounded boots, soft facets (few mesh segments). The top of the head is a lid that hinges at the back and flips open to talk; the dark mouth shows only on the front, only while open. Eyes flush on the head, movable brows, a blink, and expressions (surprised, worried, angry). Each person is easy to know by shape: General = V shape, Janitor = wider at the bottom, Assistant Scientist = tall thin cylinder, Student = small. No helmets.**
  Why: "Style: cute, rounded, toy-like." (2026-11-11) and "Improve the character design for the cutscene. Follow docs/ART_DIRECTION.md." (2026-11-12)
- **Each character has clothes and one prop so the role reads in 3 seconds:** General (navy uniform, peaked cap, gray mustache, gold shoulder boards, 3 medal blocks, belt, one pointing finger); Commander (light blue shirt, gray pants, headset, ID badge); Assistant Scientist (open white lab coat over teal shirt, round glasses, pens, clipboard, bald top with 4 chunky gray tufts); Janitor (green overalls with straps over a lighter shirt, a cap, centered gray mustache, a mop); Student (orange hoodie, brown bowl cut, large eyes, backpack, sneakers); Staff (different shirt colours, headsets). Hand props sit in the left hand. The cutscene uses the expressions: staff surprised before hiding, General angry on "I need somebody. Anybody!", the three worried at the end.
  Why: Kaleb's character brief, approved with "yes, build" (2026-11-12).
- **The intro cutscene is directed like a polished animated short: hard cuts with eased camera moves, letterbox bars, a fade-in from black, code-drawn Mars maps on the screens. Under 30 seconds. Primitive meshes and code-made graphics only.**
  Why: "Make it look like a polished animated short." Kaleb approved the 11-shot list with "yes" (2026-11-11).
- **3D art follows `docs/ART_DIRECTION.md`. Mission control is a BRIGHT room in the "Space Station" palette (warm white, navy, desaturated gray, small cyan and orange accents), with matte shared materials, a soft warm key light, a cool fill and rim light, low glow only on screens and console lights, no indoor fog, and rounded subtitle panels.**
  Why: "Apply docs/ART_DIRECTION.md to cutscene_intro.tscn" and "lets make it bright." (2026-11-11)
- **Character art proportions (leg length, arm thickness, eye and mustache sizes) stay as constants in the character scripts, not in `game_data.json`.** They are drawing choices, not game numbers.
  Why: Kaleb answered "yes, do both" to keeping them in the scripts (2026-11-11).
- **The intro shows Kaleb's own character art for the general and the janitor.**
  Why: "Add the character images I made to the intro screen" (2026-11-08).
- **The Intro screen is a short teaser before the cutscene: it keeps Kaleb's character art but does not tell the story ("points at you" and "You (the janitor)" are gone). The cutscene tells the story.**
  Why: Kaleb picked "Short teaser" when the Intro screen gave the cutscene away (2026-11-12).
- **The debrief looks like a mission report: a stamp, numbered findings with what, why and fix, and a FINAL READINGS grid.**
  Why: "Make the 'Mission success' and 'Mission failed' screens look like a mission report, not a plain list." (2026-11-08)
- **Soft fill light, so no part of the craft is pitch black.**
  Why: "Add softer fill light... so the shadow side of the spacecraft is not black." (2026-11-08)
- **The glove stays yellow when lit.**
  Why: "Make the glove stay yellow when it faces the light." (2026-11-08)
- **The dashboard is anchored and never shifts as numbers grow.**
  Why: "Stop the dashboard from shifting when a number gets longer. Anchor it in place." (2026-11-08)
- **The arm is raised above the inner voice bar.**
  Why: "Raise or move the arm so it is not hidden behind the inner voice bar." (2026-11-08)
- **Under the web renderer the glove top is lemon-yellow instead of golden. This was accepted, not fixed.**
  Why: Kaleb's rule "Fix only what looks broken" (2026-11-08). Kaleb answered "pass" when asked whether to fix it.

### Text and story
- **All inner-voice text is in its own file (`data/inner_voice.json`), "so a student writer can edit it without touching code."**
  Why: Kaleb's brief (2026-11-08).
- **All other on-screen text is in `data/story.json`: screen titles, buttons, room names and station labels.**
  Why: "All text goes in inner_voice.json" (2026-11-09) and "Room names and labels go in a data file, not in code." (2026-11-09)
- **Dashboard warning text comes from `inner_voice.json`.**
  Why: "All warning text comes from inner_voice.json, so the writer can edit it." (2026-11-08)
- **The story opener reads: "NASA Mission Control. 7:42 AM. The chief mission designer just quit..." and the general says "You're in charge now." The button says "Uh... okay?"**
  Why: the general's line is from Kaleb's brief (2026-11-08). The rest is my writing, which Kaleb accepted (guess).
- **Each failure card has three parts: what failed, why it failed, how to fix it.**
  Why: "On failure, show three things: what failed, why it failed, and how to fix it." (2026-11-08)
- **The inner voice speaks in a nervous, funny first person**, for example "Huh. Everything is inside the limits. Did I... do that right?"
  Why: Kaleb chose it. "The voice is a little clueless, but sometimes it understands." (2026-11-09)

### Scope
- **Build the full game in `GAME_PLAN.md`, in its phase order. No polish before Phase C is done.**
  Why: "GAME_PLAN.md is the design source. Build in its phase order. No polish before Phase C is done." and "Full 5-destination game." (2026-11-10)
- **Change only what the current step needs.**
  Why: "DO: Make the change. Change only what this step needs." (2026-11-08)
- **Cosmetics wait until a feature is finished.**
  Why: "I have some cosmetic changes that I want but we can do that at the end" (2026-11-08).
- **The game must run in a browser.**
  - Use the Compatibility renderer and a single-threaded Web export.
  - Why: "make sure the game runs in a browser" (2026-11-08). Single-threaded is Kaleb's own requirement. My reason: it runs on hosts like itch.io without special headers.
- **Each batch of steps ends with one full playthrough, a re-export to `build/web` and a browser test.**
  Why: "One playthrough, web export, and browser test per batch of steps." (2026-11-10)

---

## 3. Rejected choices

- **Empty "Future station: Data" and "Future station: Comms" markers in the Science bay and Comms room.** Replaced by the science pass stations (A18, 2026-11-12).
- **Bald Janitor, and round hands with no fingers on everyone.** Replaced by the Janitor's cap and the General's pointing finger (2026-11-12).
- **Broad top/bottom colour blocks as the only clothes.** Replaced by role clothes and one prop per character (2026-11-12).
- **A dark, moody war room lit mainly by the table and screens, with a dim table and subtitles with no box.** Replaced by the bright Space Station look from `docs/ART_DIRECTION.md` (2026-11-11).
- **"No clothes yet" on the characters.** Replaced by broad color-block clothes (2026-11-11).
- **The project folder `~/Desktop/OCAI Center/space-apps-game/`.** Rejected: "Use this folder for the project, not the OCAI folder" (2026-11-08). The project lives at `~/Desktop/Nasa Space App Challenge/how-did-we-get-here/`.
- **An auto-popup dashboard ("Red light pops it up") and "Both, player choice".** Rejected for "Light warns, Tab raises arm" (2026-11-08). Kaleb gave no reason beyond wanting the dashboard "hidden but also still can notify".
- **A dashboard drawn on a 3D wrist screen.** Rejected for a 2D panel above the wrist (2026-11-08). My stated tradeoff: the 3D screen's "text is smaller and harder to read" (guess that this was Kaleb's reason).
- **Free CC0 web textures (ambientCG or Poly Haven) and student-made textures.** Rejected for "Made in Godot, no downloads" (2026-11-08).
- **A green/red-only wrist light.** Rejected for green, yellow and red to match the dashboard (2026-11-08).
- **Getting or buying a spacecraft model now.** Kaleb asked "should I get a model for the space ship or will you generate one?" and then decided "lets just build it for now then upgrade" (2026-11-08).
- **The Forward+ renderer.** Replaced by Compatibility for the web build (2026-11-08).
- **A multi-threaded web export.** Kaleb required single-threaded (2026-11-08).
- **Fixing small renderer differences that aren't broken**, such as the glove tint. Not done, under "Fix only what looks broken" (2026-11-08).
- **The hangar as the walk location.** Replaced by the graybox ship and archived in `scenes/archive/` (2026-11-09).
- **The dust storm as the live event.** Replaced by the Mars shadow pass (2026-11-10): a real dust storm barely dims an orbiter's solar panels.
- **The old camera-E alarm fix.** Replaced by the Reroute Power panel (2026-11-09).
- **The corner mini-dashboard and the full-screen Tab overlay.** Replaced by the arm dashboard (2026-11-08).
- **Rooms without ceilings.** Kaleb accepted ceilings with shadowless lights at G1 (2026-11-09).

Replaced on 2026-11-10 by Kaleb's answers to the GAME_PLAN vs AGENT_SOURCE conflict list (C1–C16):

- **Only the janitor, told "You're in charge now."** Replaced by three characters, all put in charge by the general (C1, 2026-11-10).
- **Four levels with an "Assistant", and the janitor as "Very hard"** (GAME_PLAN draft). Replaced by three levels with the janitor as medium (C1, 2026-11-10).
- **Level multipliers on budget (×1.1 / ×1.0 / ×0.95), timing windows (×1.5 / ×1.0 / ×0.7) and supply use (×0.9 / ×1.0 / ×1.1).** Replaced the same day: the levels only change guidance (2026-11-10). It made the Student with the Large rocket unable to win.
- **"Swap the scrubber" as the air task.** Replaced by "run the oxygen generator": a scrubber removes carbon dioxide, it makes no oxygen (2026-11-10).
- **Crew uses only 90 days of supplies during the 730-day Arrival.** Replaced by the real 730 days (2026-11-10).
- **A 3-second automatic pause after each setup answer.** Replaced by a Next button: 3 s was too short to read the longer voice lines (2026-11-10).
- **"If a choice is not covered, ask one short question. Do not guess."** Replaced: use a GAME_PLAN DEFAULT when there is one and list it; otherwise ask (C2, 2026-11-10).
- **The shadow pass as a Flight event** (GAME_PLAN draft, Phase A step 5). Replaced: it stays a Mars-orbit event in Arrival (C3, 2026-11-10).
- **Food, water, air, heat, power and data as one row of trip meters** (GAME_PLAN draft). Replaced: the six resources keep their names, and food, water and air are "crew supplies" (C4, 2026-11-10).
- **A heat meter and a thermal-panel task** (GAME_PLAN draft). Replaced by the heater switch only (C6, 2026-11-10).
- **The mission fails only on the 2–3 goal rules** (GAME_PLAN draft). Replaced: any meter that goes red can fail it (C7, 2026-11-10).
- **The launch vehicle sets max mass and part of the budget** (GAME_PLAN draft). Replaced: the real limits stay, and the rocket changes the launch sequence and its cost (C8, 2026-11-10).
- **All numbers in ONE shared file, `data/game_data.json`.** Replaced by the GAME_PLAN data files (C9, 2026-11-10).
- **Space as the timed-press key everywhere** (GAME_PLAN draft). Replaced: Space only in Launch, E on the ship and surface (C10, 2026-11-10).
- **The janitor's inner voice "is often wrong"** (GAME_PLAN draft). Replaced: the voice is never wrong, and only knows what its character knows (C11, 2026-11-10).
- **Four ship rooms (Bridge, Power room, Science bay, Comms room).** Replaced by five, adding Life Support (C12, 2026-11-10).
- **"Keep the proof of concept small: one character, one mission, three parts with 2–3 versions each, and one live event."** Replaced by the full 5-destination game (C13, 2026-11-10).
- **The full playthrough, re-export and browser test only in a feature's last step.** Replaced by once per batch of steps (C14, 2026-11-10).
- **Screen flow "Intro → Character select → Mission select → Build → Review → Walk → Debrief → Try again" (Try again returns to Build).** Replaced by the GAME_PLAN flow and three report buttons: Retry from checkpoint, Same design / new destination, Start fresh (C15, 2026-11-10).

---

## 4. My corrections

Kaleb never answered a step with "fail". Every change Kaleb asked for to existing work is listed below.

1. **Project location (2026-11-08)**
   - **What I did:** proposed creating the project in `~/Desktop/OCAI Center/space-apps-game/`, near the folder the session started in.
   - **What Kaleb wanted:** "Use this folder for the project, not the OCAI folder '/Users/kalebtovar/Desktop/Nasa Space App Challenge'".
   - **Rule:** confirm the project folder before creating files. Never default to the session's working folder or another project's folder.

2. **Runtime error after new files (2026-11-08)**
   - **What I did:** wrote new autoload scripts from outside the editor. Godot's uid cache didn't know them, so `GameState` was Nil.
   - **What Kaleb sent:** "Invalid assignment of property or key 'character_id' with value of type 'String' on a base object of type 'Nil'."
   - **Rule:** after adding new files or settings, tell Kaleb to use **Project → Reload Current Project** before pressing Play. Explain errors as a teaching moment.

3. **Missing extra feature (2026-11-08)**
   - **What I did:** built walking with no jump.
   - **What Kaleb wanted:** "can we get a jump feature please and do step 9 too".
   - **Rule:** small feel features can be added mid-plan when Kaleb asks. Kaleb may also ask to batch two steps.

4. **Debrief judged only the build (2026-11-08)**
   - **What I did:** a mission counted as a success even when live Data was red at the end.
   - **What Kaleb wanted:** "yes we can count it as failure, they should have goals that will make it so that they need to pay attention to what they need to do".
   - **Rule:** the end state of the live mission must count. Any goal the player can see go red must be able to fail the mission.

5. **Control hints too small (2026-11-08)**
   - **What I did:** used small fonts in the walk HUD.
   - **What Kaleb wanted:** "The control hints at the top of the walk screen are too small to read. Make them larger."
   - **Rule:** size all HUD text for 10–15-year-olds.

6. **All text too small (2026-11-08)**
   - **What I did:** used default and small font sizes across the screens.
   - **What Kaleb wanted:** "Make all text larger and easier to read. Students aged 10–15 will play this."
   - **Rule:** use one shared theme with large type variations (base 26, body 28, title 50). Never set font sizes per node.

7. **Plain colors (2026-11-08)**
   - **What I did:** used dark gray screens with yellow accents and per-scene StyleBoxes.
   - **What Kaleb wanted:** "Use a navy and orange color theme on all 2D screens (intro, build, review, debrief)."
   - **Rule:** put every 2D color in the shared theme file, and keep a consistent identity across all screens.

8. **No character art (2026-11-08)**
   - **What I did:** made an intro screen with text only.
   - **What Kaleb wanted:** "Add the character images I made to the intro screen".
   - **Rule:** leave slots for Kaleb's own art, with picture paths in data and a visible "Picture goes here" fallback.

9. **Plain-list debrief (2026-11-08)**
   - **What I did:** made a debrief that was a plain list of cards.
   - **What Kaleb wanted:** "Make the 'Mission success' and 'Mission failed' screens look like a mission report, not a plain list."
   - **Rule:** outcome screens should feel like an in-world document, not a debug list.

10. **Issues I found myself (2026-11-08)**
    - **What I did:** I reported four rough edges: a black shadow side, the arm hidden behind the voice bar, the dashboard shifting, and a cream glove.
    - **What Kaleb wanted:** "Your four items (do all four)".
    - **Rule:** report the rough edges you notice at the end of each step. Kaleb will add them to the list.

11. **Missing error help (2026-11-08)**
    - **What I did:** the W3 test steps said what to expect, but not what to do if errors appeared.
    - **What Kaleb asked:** "what do I do if it does show errors:"
    - **Rule:** every MY TEST includes "If you see an error" steps, for example a table of likely errors and fixes. Why: it saves time when a test fails (Kaleb, 2026-11-09).

12. **Commit each step (2026-11-09)**
    - **What I did:** left four passed steps uncommitted and offered to go on to step 5.
    - **What Kaleb wanted:** "Step 4 passed. Commit it. Do not start step 5."
    - **Rule:** commit after each step that passes its self-check. "Do not start step 5" was a one-time stop, not a rule (Kaleb, 2026-11-09).

---

## 5. Repeated questions

- **"Should red data (a live dashboard row) at the end of the walk fail the mission?"** I asked this **4 times**: in the Dashboard Step 6 report, the Dashboard Step 7 report, the Arm plan and the Arm Step 5 report (2026-11-08).
  - **Kaleb's answer:** "yes we can count it as failure, they should have goals that will make it so that they need to pay attention to what they need to do" (2026-11-08).
  - **Lesson:** ask an open design question once, record it, and don't repeat it in every report. Or ask it as a blocking question.
- **The arm/texture question set** appears twice in the transcript with the same answers. This is a logging duplicate, not a second ask.
- **"Tell me when it works / Say 'pass'"** ended every step. This was the agreed protocol, not a real repeated question.

No other question was asked more than once.

---

## 6. My acceptance checks

What Kaleb looks at or tests before saying "pass":

1. **Kaleb follows my MY TEST list exactly in the Godot editor.** Kaleb presses F5, clicks the listed buttons and compares the result with the "Expect:" lines.
2. **Kaleb requires a self-check before testing.**
   - I run `cd "/Users/kalebtovar/Desktop/Nasa Space App Challenge/how-did-we-get-here" && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit`, fix errors and warnings from our scripts, and show the final output.
   - "Show me the final check output." (2026-11-08)
3. **Visible proof for data steps.** For example, "okay, i see the print out, everything looks good" (2026-11-08) after the data-loader printout.
4. **Visual details on the dashboard.** "yes, the warning and max bar are good" (2026-11-08): the warning and limit markers and bars.
5. **Readability for kids.** Kaleb checks font sizes, the control hints and whether the arm or dashboard is hidden behind other UI.
6. **Nothing else broke.** Each feature's last step is a full playthrough from the intro to Try Again: "Confirm nothing else broke." (2026-11-08)
7. **Both outcomes play.** (From 2026-11-10 the shadow pass runs in Stage 4 Arrival, orbit type. These tests stay the same there.) A losing round (do nothing at the shadow pass → MISSION FAILED, Power alarm) and a winning round (reroute power → MISSION SUCCESS). The winning build is Medium solar + Basic camera + Large antenna (set in step 8, 2026-11-10).
   - Win: turn the heater off at the power panel when the alarm rings (about 20 s), then back on after "Out of the shadow!" (about 40 s) → MISSION SUCCESS.
   - Lose: the same build, do nothing → MISSION FAILED, with the "Power alarm" card.
   - Harder test: Small solar + Basic camera + Large antenna, where the heater can be off 30 s at most (for example, off at 22 s, back on by 52 s).
   - The old winning build, Large solar + High-res, fails the real budget limit since step 7e.
8. **Browser check.** After the web task, Kaleb plays both rounds in the browser from `build/web` using `python3 -m http.server`.
9. **Walkability for 3D layout.** Kaleb walks through every room and checks that the walls are solid.

**Optional, not required:** the "Try it" and "Bonus test" data edits in each report. Why: fastest path. "We can add it back later." (Kaleb, 2026-11-09)

---

## 7. How I work

- **How Kaleb gives tasks.** Each feature starts with a **pasted, structured brief**. It contains:
  - "Next task: ..."
  - A short "What it does" or layout section.
  - Rules: numbers go in `game_data.json`, text goes in `inner_voice.json` or `story.json`.
  - A numbered step list (6–9 steps).
  - It ends with **"Start with step 1 only."**
- **Step 1 is always read and plan, with no file changes.** For example: "Read the current walk scene. Tell me what moves to the new ship and what stays. Change no files."
- **The last step of each feature** is a full playthrough. After the web task it also includes a re-export to `build/web` and a browser test.
- **Step size.** One small, testable change per step: one scene, one connection, one visual fix. Most steps are passed within 5–15 minutes.
- **The step-and-check protocol** (pasted 2026-11-08, then "Same step-and-check system" for every later feature):
  1. **PLAN:** 2–3 sentences on what changes and which files.
  2. **DO:** change only what this step needs.
  3. **SELF-CHECK:** run Godot headless, fix errors and show the output.
  4. **MY TEST:** exactly what to click or press, and what should appear.
  5. **WAIT:** stop until Kaleb says pass. If the task asks for several steps in a row, wait after the last step only. On fail, fix only that problem.
     Why: "WAIT: stop until Kaleb says pass. If the task asks for several steps in a row, wait after the last step only. On fail, fix only that problem." (2026-11-09)
- **Kaleb's replies** are short: "pass", "PASS", "passs", "lets continue", "go". "pass" with no comment accepts my recommended defaults. Kaleb uses "pass, but..." for changes, though that was never needed.
- **Teaching focus.** "I am a beginner in Godot. Explain each step in simple English, so I can teach it to students." Every report includes teaching ideas, "Try it" and student challenges.
- **Decisions.** Kaleb answers multiple-choice questions by picking the "(Recommended)" option each time. Kaleb gives reasons in their own words only for gameplay goals, such as the red-data answer.
- **Deferral.** Kaleb parks polish for later ("we can do the cosmetics stuff at the end") and then pastes a single cosmetics list that mixes their items with mine.
- **What Kaleb does first in a session:** pastes a context brief:
  - who Kaleb is (Magikid coach, 5 students, Space Apps dates)
  - the tools (Godot 4, GDScript, beginner)
  - the game premise and scope
  - the data rules
  - "FIRST STEP: Do not write code yet... give me the folder and file structure and the list of build steps... Then wait for my approval."
- **What Kaleb does last in a session:** passes the last step, checks that it is committed, then stops. Agents commit each step that passes its self-check without waiting to be asked (see correction 12). (2026-11-09)
- **Session length.** The whole game was built in one long session (2026-11-08 00:34 to 2026-11-09 22:44) with 3 context compactions. It was started from another project's folder (Motion Studio).
- **Downloads.** Ask before downloading any model, package or tool. Source: Kaleb confirmed for this game (2026-11-09).

---

## 8. Tech setup

- **Engine:** Godot **4.7.2** (stable), GDScript. Installed at `/Applications/Godot.app`.
- **Renderer:** `gl_compatibility` (desktop and mobile) and `config/features = "4.7", "GL Compatibility"`. It was switched from Forward+ for the web build.
- **Physics:** Jolt Physics.
- **Window:** viewport 1280×720, stretch mode `canvas_items`, aspect `expand`.
- **Autoloads:**
  - `Data` (`scripts/autoload/Data.gd`): loads the 3 JSON files.
  - `GameState` (`scripts/autoload/GameState.gd`): choices, totals, limits, live mission math, failures.
  - `Textures` (`scripts/autoload/Textures.gd`): makes textures in code from the recipes in data.
- **Theme:** `theme/game_theme.tres`, set as the project theme (`gui/theme/custom`).
  - Type variations: TitleText, HeadingText, BodyText, SmallText, AccentText, TableText, BannerText, SmallButton, NavyPanel, VoiceBar, ScreenBackground.
  - Scenes use `theme_type_variation`, never per-node font sizes.
- **Plugins / addons:** none.
- **Folder structure:**
  ```
  how-did-we-get-here/
    project.godot  export_presets.cfg  icon.svg  .gitignore  .editorconfig  .gitattributes
    data/        game_data.json (all numbers)  story.json (screen text)  inner_voice.json (voice text)
    scenes/      one .tscn per screen/component; archive/ (old hangar walk, .gdignore'd)
    scripts/     one .gd per scene, same name; autoload/ (Data, GameState, Textures)
    theme/       game_theme.tres
    assets/characters/  general.png  janitor.png  (Kaleb's art)
    build/web/   web export (.gdignore'd, git-ignored)
  ```
- **Naming:**
  - Scenes and scripts use `snake_case` and share a name: `scenes/build.tscn` ↔ `scripts/build.gd`.
  - Some scripts have no scene and build their 3D in code from data: `ship.gd`, `spacecraft.gd`, `power_panel.gd`.
  - Autoload scripts use PascalCase (`Data.gd`, `GameState.gd`, `Textures.gd`).
  - Nodes use PascalCase. Unique `%Name` nodes are used for script access.
  - JSON keys use snake_case. Every JSON section has a `_readme` key in plain English for students.
- **Scenes:**
  - Screens: intro, character_select, mission_select, build, review, walk, debrief.
  - Components: choice_card, dashboard, dashboard_row, inner_voice_bar, player, arm, reroute_panel.
  - Test bench: dashboard_test.
- **How the code is written:**
  - `.tscn` files are written as text by Claude. Transform3D values are row-order and are written with `var_to_str`.
  - Poses are Marker3D nodes.
  - First-person overlay meshes use `no_depth_test` + `render_priority`.
  - 3D interaction uses Area3D reach zones with `meta part_id` and the group "player".
  - Input actions are created in code in `player.gd`.
  - Lights are shadowless in the ship, for web speed.
- **Self-check:**
  - Kaleb's command: `cd "/Users/kalebtovar/Desktop/Nasa Space App Challenge/how-did-we-get-here" && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit`. The `cd` matters because an agent's working folder can reset between commands.
  - I also kept a scratch copy of the project with a `Tester` autoload for automated playthroughs and screenshots, run windowed at 1280×720 in the foreground.
  - Don't use `--check-only --script`, because it reports false autoload errors.
- **Editing gotchas:**
  - Edit `game_data.json` by inserting text. Don't use `json.dump`, because it reformats the compact texture recipes.
  - Reload the project in the editor after adding files.
- **Export:** one preset, "Web".
  - Platform Web, `variant/thread_support=false` (single-threaded).
  - Export path `build/web/index.html`.
  - Export filter: all resources.
  - Needs the 4.7.2 export templates (`web_nothreads_*`).
- **Testing the web build on the Mac:** `cd build/web && python3 -m http.server 8000`, then open http://localhost:8000. Remote Deploy → Run in Browser also works.
- **Git:**
  - Initialized 2026-11-09 on branch `main`. First commit: `2e7a732`. It had 4 commits by the end of 2026-11-09. Run `git log --oneline` for the current history.
  - `.gitignore` covers `.godot/`, `/android/`, `/build/` and `.DS_Store`.
  - No global git identity is set on this Mac. The commit used Kaleb's name with `-c` flags. (guess on the exact method)

---

## 9. NASA data used

**Every NASA or mission number in `data/game_data.json` now has real NASA data or a written game-design choice (steps 7a–7g, 2026-11-10). Layout, look and timing settings (walk, arm, dashboard, ship, power_panel) are game-design choices with no source. No value is marked `"source": "PLACEHOLDER"`.** The steps: the solar panels and the heater (7a), the cameras (7b), the antennas (7c), the spacecraft base (7d), the mission limits (7e), the shadow pass event (7f), and the mission clock and the janitor's multipliers (7g). The table lists each dataset, its source, and where the game uses it. The full links are in each `source` string in `game_data.json`.

| Dataset | Source link | Where the game uses it |
|---|---|---|
| Mission limits for `mars_ice`: budget max 671 (MAVEN's total cost), mass max 1,031 kg (MRO dry mass), comms min 0.6 Mb/s (MRO's rate when Mars is farthest), lifetime min 24 months (MRO's two-year science phase). Power min 0 and data min 4 Gb/day: game-design choice. Every warning and bar_max: game-design choice | MAVEN press kit (Nov 2013), Quick Facts; MRO launch press kit (Aug 2005) | Build dashboard, Review table, walk dashboard, wrist light, debrief |
| Spacecraft base = MRO spacecraft without the swappable parts: budget 490 ($720M MRO total − 230 for the game costs of MRO's parts), mass 848.7 kg (1,031 kg MRO dry mass − 96.6 − 65 − 20.7; CTX stays in the base). Power −40: no public source. Communications 0, data 0, lifetime 30: game-design choice | MRO launch press kit (Aug 2005), Quick Facts | Totals on Build and Review, live values |
| Solar panel small / medium / large = Mars Odyssey array (32.3 kg, 750 W), MAVEN arrays (1,135 W; mass: no public source, keeps the game value 60 kg), MRO arrays (96.6 kg, 2,000 W). Costs: no public source. Lifetime bonus: game-design choice | NASA NTRS papers 20030065626 and 20070029236; Odyssey arrival and MRO launch press kits; MAVEN fact sheet 2013 | Build choices, 3D parts, shadow pass power math |
| Camera basic / high-res = MRO CTX (3 kg, 7 W, 4.8 Gb/day), MRO HiRISE (65 kg, 60 W, 16.4 Gb/day). Costs: no public source | NASA MRO science instruments page; CTX data guide in NASA PDS (ctxsis.pdf, "approximately 3.5 Tb"); HiRISE team science paper, McEwen et al. 2007 JGR ("more than 12 Tb") | Build choices, data collection rate, Reroute panel |
| Antenna small / large = Mars Odyssey 1.3 m high-gain antenna (3.15 kg with its medium-gain antenna, 0.124 Mb/s), MRO 3 m high-gain antenna (20.7 kg, 6 Mb/s). Both use 172 W (MRO's amplifier power used; for the small antenna a game-design choice). Costs: no public source | NASA PDS Odyssey radio science catalog (inst.cat, "Mass (kg) 3.150"); NASA Mars Relay Description 2010 ("124.425 kbps", and 5.2 Mbps for MRO); MRO telecom summary, DESCANSO (Table 2-1, "rates as high as 6 Mbps") | Build choices, Reroute panel |
| Heater = all MRO heaters: power −300 W. Off = 0.2 lifetime months lost per second (game-design choice) | NASA MRO thermal systems page ("As much as 300 watts") | Reroute panel, live lifetime |
| Shadow pass event (Mars eclipse): 100% solar drop (in shadow the panels make nothing and the batteries take over), batteries give 400 W (game-design choice; MRO's real batteries could give about 1,900 W: 2 × 1,600 Wh × 40% usable over a 40-minute shadow, so the alarm would never ring), lasts 20 s of the 60 s walk (game-design choice, about one third, like the real 40 of every 112 minutes), starts at 20 s and 15 s to fix (game-design choice) | MRO launch press kit (Aug 2005), Power Subsystem; JPL "Mars Reconnaissance Orbiter Preparing for Years Ahead" (Feb 9, 2018); archived JPL MRO "Electrical Power" page (2009) | Walk alarm, Reroute mini-game, Reroute panel "Power available" |
| Mission clock: 0.4 months per second (game-design choice: the 60 s walk = MRO's real 24-month primary science phase), 30.4 days per month (calendar math, 365.25 / 12; 24 × 30.4 = 730 days, so the basic camera collects about 3,500 Gb, like CTX's real 3.5 Tb), turned-off parts stop power, data and comms (game rule) | MRO launch press kit (Aug 2005), Quick Facts | Walk clock, data total, live limits, debrief mission time |
| Character multipliers (janitor all 1.0): game-design choice, 1.0 = the real mission limits from 7e, unchanged | none (game-design choice) | `GameState.get_limits` |

The inner-voice text uses real-world reasoning in plain words, for example "NASA can't pay for a mission that costs more than its budget." The mission concept, mapping subsurface ice on Mars, is NASA-style, but no dataset is cited. All placeholders were replaced with real NASA data or a written game-design choice on 2026-11-10. Students can check each source link, and any new made-up number must be marked PLACEHOLDER until it is replaced.

---

## 10. Unfinished work

- **Graybox ship, G5:** show the chosen part version in each room, for example the solar panels through the Power room window, with E inspection at the windows. Not started; Kaleb said "Do not start step 5." The spacecraft is still parked off-map at x=40 in `scenes/walk.tscn` as a stand-in until G5.
- **Graybox ship, G6:** a dashboard wall screen on the Bridge. My planned approach was a second dashboard on a SubViewport on a 3D quad. Not started.
- **Science and Comms stations:** they run one science pass (capture, then downlink) in Arrival. The Data and Comms mini-games (TASKS 15, 16) and the three passes of GAME_PLAN wait for Phase C.
- **Real 3D models:** the `"model"` slot in each part version is empty.
- **Ideas I offered that Kaleb never picked up:**
  - an alarm sound
  - more characters (easier and harder) and more missions
  - a one-page student README or guide
  - uploading to itch.io
- **Leftover test and legacy code:**
  - `scenes/dashboard_test.tscn` and `scripts/dashboard_test.gd`, a dashboard test bench (guess: kept on purpose).
  - The unused compact-dashboard mode and the `"hint_small": "Tab = bigger"` text in `story.json`, left over from the corner dashboard. (guess)

---

## Uncertain lines answered by Kaleb (2026-11-09)

1. Limits (§2 Player experience): replaced with Kaleb's rule. Limits matter, but they're not so tight that the player plays scared.
2. Downloads (§7): kept. Kaleb confirmed it for this game.
3. Correction 11 (§4): kept as a rule. Every MY TEST includes "If you see an error" steps.
4. Data-only edits (§6): removed from the required checks. "Try it" and "Bonus test" edits are optional.
5. Inner voice tone (§2): kept. Kaleb chose it.
