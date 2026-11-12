# Material library

Every 3D thing in the intro cutscene (the room and the people) uses one of these
materials. They are all matte (roughness 0.9, metallic 0, specular 0.2).

To change a colour: click the `.tres` file in the FileSystem, then change
**Albedo > Color** in the Inspector. Every mesh that uses it changes at once.

| Group | Files | Colours |
|---|---|---|
| Room | `room_*` | walls, panels, floor, table, walkway, dark trim, consoles, rocket |
| Accent | `accent_cyan`, `accent_orange` | small flat colour touches |
| Glow | `glow_cyan`, `glow_orange` | the ONLY glowing ones (screens, console lights). Low energy. |
| Skin | `skin_light`, `skin_medium`, `skin_dark` | faces and hands |
| Cloth | `cloth_*` | tops and bottoms of the people |
| Hair, face | `hair_*`, `eye_black`, `mouth_dark`, `glasses`, `shoe_dark`, `gold_trim` | small parts |

Each `.tres` file also has a short comment at the top that says what it colours.
The palette is the "Space Station" palette in `docs/ART_DIRECTION.md`.
