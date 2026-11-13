# How Did We Get Here?

A mission-design game for the NASA Space Apps Challenge 2026, challenge
"Space Mission Design Game". Made by a team of students aged 10–15 and their coach.

The chief mission designer quits, and the general puts someone new in charge:
a scientist (easy), the janitor (medium) or a student (hard). An inner voice helps
you answer the setup questions, build a spacecraft that fits six limits (budget,
mass, power, communications, data and mission lifetime), launch it, keep the ship
and crew going on the way, and then arrive and do the science. At the end you give
the general your report.

## How to play

- **In a browser:** open the published link, or run the web build on your own
  computer:
  `cd build/web && python3 -m http.server 8000`, then open http://localhost:8000.
- **In Godot 4.7:** open this folder as a project and press Play (F5).
- **Keys:** WASD or the arrow keys to walk, E to use things, Tab to raise the
  wrist dashboard, Space for timed presses where you cannot walk (launch, landing).

## NASA data used

Every number in `data/*.json` has a `source` field: a NASA link, a written
game-design choice, or the word `PLACEHOLDER` (made up for now, to be replaced by a
student with real data before the final submission). The NASA sources include:

- NASA Planetary Fact Sheets for Mars and Jupiter (NSSDC):
  https://nssdc.gsfc.nasa.gov/planetary/factsheet/marsfact.html,
  https://nssdc.gsfc.nasa.gov/planetary/factsheet/jupiterfact.html
- Mars Reconnaissance Orbiter launch press kit and instrument pages (JPL, NASA Science)
- MAVEN fact sheet and press kit (mission cost)
- Mars Odyssey arrival press kit and the Mars relay description
- NASA-STD-3001 Technical Brief on water (crew water use)
- NASA Technical Reports Server papers on deep-space crew logistics (food and oxygen)
- Mars 2020 Perseverance, Curiosity (Gale Crater), Europa Clipper mission pages
- JPL's map of water ice on Mars (Arcadia Planitia)

The full list, with the exact quote for each number, is in the data files.

## Use of AI tools (required disclosure)

The game idea, the story, the characters and every design choice come from the team.
AI was not used to come up with the idea.

AI coding assistants (Anthropic's Claude, through Claude Code) helped write the
GDScript code, the Godot scenes, the data file structure and some of the in-game
text, always following the team's written design (`GAME_PLAN.md`) and the team's
recorded decisions (`AGENT_SOURCE.md`). Commits that an AI assistant helped make are
marked in the git history with a `Co-Authored-By: Claude ...` line. AI tools also
looked up NASA pages for some numbers; every such number has its NASA source link in
the data files. All 3D shapes are built from simple primitive meshes in code, and the
game has no AI-generated video or audio. The character pictures on the intro
screen are in `assets/characters/`. No NASA logos, flags or
mission insignia are used.

## Safety note

The game and its demo contain no photos, video, voices or likenesses of anyone
under 18.
