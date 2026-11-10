# How Did We Get Here?

A Godot 4.7.2 (GDScript) mission-design game for the NASA Space Apps Challenge 2026
(Nov 14–15), challenge "Space Mission Design Game". The chief mission designer quits,
and the general puts the janitor in charge. The player must plan a NASA-style science
mission ("Map the ice on Mars") with no training, guided by an inner voice. They build
a spacecraft, review six resources (budget, mass, power, communications, data, mission
lifetime), walk the ship in first person, survive a dust storm with the Reroute Power
mini-game, and read a mission report. Players are students aged 10–15. Kaleb coaches a
team of 5 Magikid students and teaches from this project.

## Rules

- Follow `AGENT_SOURCE.md`. It records how Kaleb makes design choices.
- If a choice is not covered there, ask one short question. Do not guess.
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
- Keep numbers in `data/game_data.json`, not in code.
- Keep inner-voice text and dashboard warning text in `data/inner_voice.json`.
- Keep all other on-screen text (screen titles, buttons, room names, station labels)
  in `data/story.json`.
- Take all 2D colors and font sizes from the shared theme `theme/game_theme.tres`.
  Never set font sizes on a single node.
- The game must run in a browser: use the Compatibility renderer and a
  single-threaded Web export.
- The last step of each feature is a full playthrough, a re-export to `build/web`,
  and a browser test. If a task asks for several steps in a row, do these once, at
  the end of the batch.
- Any value marked PLACEHOLDER must be replaced with real NASA data and a source link
  before the final submission.
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
