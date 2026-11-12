# How Did We Get Here?

A Godot 4.7.2 (GDScript) mission-design game for the NASA Space Apps Challenge 2026
(Nov 14–15), challenge "Space Mission Design Game". The chief mission designer quits,
and the general puts a person in charge: a scientist (easy), the janitor (medium) or a
student (hard). Guided by an inner voice, the player answers setup questions, builds a
spacecraft against six resources (budget, mass, power, communications, data, mission
lifetime), launches it, keeps the crew and ship alive in flight, and arrives at one of
five destinations. At Mars orbit they survive a shadow pass with the Reroute Power
mini-game. The game ends with a report to the general. The full design is `GAME_PLAN.md`. Players are students aged 10–15. Kaleb coaches a
team of 5 Magikid students and teaches from this project.

## Rules

- GAME_PLAN.md is the design source. Build in its phase order. No polish before Phase C is done.
- Follow `AGENT_SOURCE.md`. It records how Kaleb makes design choices.
- If GAME_PLAN.md gives a DEFAULT, use it and list it. Otherwise ask one short question.
- Ask each open design question once, as a blocking question, and record the answer
  in `AGENT_SOURCE.md`. Do not repeat it in later reports.
- Step 1 of a feature is read and plan only, with no file changes.
- Fix only what looks broken. Save cosmetic changes for the end of a feature.
- List any rough edges you noticed at the end of each step, but do not fix them
  unless Kaleb asks.
- Report every step as PLAN, DO, SELF-CHECK, MY TEST, then WAIT.
  - PLAN: 2–3 sentences on what changes and which files.
  - DO: change only what this step needs.
  - SELF-CHECK: run the command below, fix errors and warnings from our scripts,
    show the output.
  - MY TEST: exactly what to click or press, and what Kaleb should see.
  - WAIT: stop until Kaleb says pass. If the task asks for several steps in a row,
    wait after the last step only. On fail, fix only that problem.
- Every MY TEST includes "If you see an error" steps.
- After adding new files or settings, remind Kaleb to use Project → Reload Current
  Project before pressing Play.
- Keep numbers in the data files, not in code: `data/game_data.json`,
  `destinations.json`, `parts.json`, `events.json`, `supplies.json`, `timing.json`,
  `levels.json` (GAME_PLAN.md section 11).
- Keep inner-voice text and dashboard warning text in `data/inner_voice.json`.
- Keep all other on-screen text (screen titles, buttons, room names, station labels)
  in `data/story.json`.
- Take all 2D colors and font sizes from the shared theme `theme/game_theme.tres`.
  Never set font sizes on a single node.
- The game must run in a browser: use the Compatibility renderer and a
  single-threaded Web export.
- Each batch of steps (a batch heading in `TASKS.md`) ends with one full playthrough,
  a re-export to `build/web`, and a browser test, done once at the end of the batch. The playthrough covers a losing round and a winning
  round (AGENT_SOURCE.md section 6, items 7–9), and a walk through every room if the
  layout changed. The agent does the re-export. MY TEST tells Kaleb how to do
  the full playthrough and the browser test: `cd build/web && python3 -m http.server
  8000`, then open http://localhost:8000.
- A student replaces PLACEHOLDER values with real NASA data and a source link, or a
  written game-design choice that Kaleb passes, before
  the final submission. Agents never invent real-looking numbers. Mark every new
  made-up number `"source": "PLACEHOLDER"`.
- Ask before downloading anything.
- Commit after each step that passes its self-check, with a one-line message.
- Explain each step in simple English. Kaleb teaches it to students.

## Self-check command

```
cd "/Users/kalebtovar/Desktop/Nasa Space App Challenge/how-did-we-get-here" && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit
```

## Judging criteria

Check every feature against the five Space Apps judging criteria:

1. Influence (called Impact in older years; confirm in the 2026 guide on Nov 13)
2. Creativity
3. Validity
4. Relevance
5. Presentation

## Keeping the record current

When Kaleb makes a new design choice, add it to `AGENT_SOURCE.md`: one line, then
"Why:" with Kaleb's own words and the date. If it replaces an earlier choice, replace
the old line in section 2, and move the old choice to section 3, Rejected choices,
with the date.

## Art direction

Follow docs/ART_DIRECTION.md for all 3D art.
