# Student Guide: make the game yours

You do not need to write code. The game reads its numbers and its words from small text files.
You can change them, or add your own things. Two jobs:

1. Swap a made-up number (a PLACEHOLDER) for a real NASA number.
2. Make a content pack: your own part, place or voice line.

Always make a copy of the project before you start, and ask your coach if you are stuck.

---

## Job 1: Change a PLACEHOLDER to a real NASA number

A PLACEHOLDER is a number we made up so the game could run. Every one is marked
`"source": "PLACEHOLDER"`. A real number has a link to where NASA says it.

1. Open the data file in the `data/` folder (`game_data.json`, `events.json`, `destinations.json`...).
2. Search the file for the word `PLACEHOLDER`. Pick one.
3. Look at the words next to it. They say what the number means (for example "hours the ground station is in view").
4. Find the real number on a NASA website (nasa.gov, science.nasa.gov or jpl.nasa.gov).
   Do not use news sites. If NASA has no number, write what you chose and why.
5. Change the number after `"value":` and replace the word PLACEHOLDER with the link:

```json
"downlink_hours": {
  "value": 6,
  "source": "https://science.nasa.gov/... (the page where you found it)"
}
```

6. Press Play. If the game says "typo", look for a missing comma or quote near your change.

Keep the same name on the left of the colon. Only change what is on the right.

---

## Job 2: Make a content pack

A pack is one folder inside `content/`. The folder name is your name: `content/sam/`.
Look at `content/_example_pack/` first. It adds one solar panel called "Example Wing (pack)".
It is switched OFF, because its name starts with `_`. To see it work, rename the folder to `example_pack`
(no `_`), then press Play. Rename it back to switch it off.

Inside your folder, put any of these files. Each one looks like the game's own file, but holds only your new things:

| File | What it adds | Starts with |
|---|---|---|
| `parts.json` | a new part version | `{ "parts": { "solar_panel": { "versions": { ... } } } }` |
| `destination.json` (not destinations) | a new place to go | `{ "destinations": { ... } }` |
| `events.json` | a new event (it is read, but the game does not run it yet: Flight uses a fixed plan) | `{ "events": { ... } }` |
| `mission.json` | a new mission goal | `{ "missions": { ... } }` |
| `inner_voice.json` | inner voice lines | same shape as `data/inner_voice.json` |
| `story.json` | screen words | same shape as `data/story.json` |

Rules:

- A new part version needs: a `name`, `effects` (a number for budget, mass, power, communications, data and mission_lifetime), a `source`, and a `look` with a `size`.
- Every new part also needs a voice line in your `inner_voice.json`, under `parts` > the part > your version name.
- Every made-up number gets `"source": "PLACEHOLDER"` until you find a real one (Job 1).
- A new place or mission also needs its words in `story.json` and a voice line for each level: easy, medium and hard.
- Your pack can only ADD new names. A destination, mission, event or part that the game already has is closed: that entry is left out and a note tells you. You can add a new version to a part the game already has (under `"versions"`), but you cannot change its other settings.
- `story.json` and `inner_voice.json` also only add new lines. A line the game already has stays as it is.
- Every fact of a new place looks like `{ "value": ..., "source": ... }`, and a new mission needs all six limits (rule, value, warning, bar_max, source).
- Only these file names are read: `destination.json`, `parts.json`, `events.json`, `mission.json`, `inner_voice.json`, `story.json`. Another `.json` name is ignored, and the game tells you.
- Start a folder name with `_` (like `_sam`) to switch the pack off.

Then press Play. In the Output panel you will see `Content pack 'sam' loaded.`

### If your pack has a mistake

A pack with a mistake never stops the game from starting. The game skips your whole pack (nothing from it is added) and says why, for example:

`Content pack 'sam' was SKIPPED: parts.json > camera > mini is missing "source"`

Fix the thing it names and press Play again. The most common mistakes: a missing comma, a missing quote,
or no voice line for the new part.

---

Check your work against the five judging questions: Impact, Creativity, Validity (are your numbers real, with a link?),
Relevance and Presentation.
