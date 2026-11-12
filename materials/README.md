# Material library

Every 3D thing in the intro cutscene (the room and the people) uses one of these
materials. They are all matte (roughness 0.9, metallic 0, specular 0.2).
The palette is the "Space Station" palette in `docs/ART_DIRECTION.md`.

## How to change a colour
Click the `.tres` file in the FileSystem, then change **Albedo > Color** in the
Inspector. Every mesh that uses it changes at once.

**Glow materials (`glow_cyan`, `glow_orange`):** change BOTH **Albedo > Color** AND
**Emission > Color**. If you change only one, the glow keeps the old colour.
Lower **Emission > Energy Multiplier** to make the glow dimmer.

## Comments in `.tres` files
Godot deletes `;` comments inside `.tres` and `.tscn` files when it saves them.
So this README is the real list of notes. Do not rely on comments in those files.

## What each material colours
- `accent_cyan`: Accent: cyan, NOT glowing. Small flat cyan parts.
- `accent_orange`: Accent: orange, NOT glowing. The door stripe, the map marker, small parts.
- `cloth_commander_top`: Cloth: Commander jacket (top).
- `cloth_cyan_gray`: Cloth: cyan-gray. Assistant Scientist trousers (bottom).
- `cloth_dark_gray`: Cloth: dark gray. Commander and Staff trousers (bottom).
- `cloth_general_top`: Cloth: General jacket (top).
- `cloth_labcoat_white`: Cloth: white lab coat. Assistant Scientist top.
- `cloth_mustard`: Cloth: mustard. Staff 2 top.
- `cloth_navy`: Cloth: navy. General trousers, Student trousers, General cap.
- `cloth_orange_hoodie`: Cloth: orange. Student hoodie (top).
- `cloth_slate`: Cloth: slate blue. Staff 3 top.
- `cloth_teal`: Cloth: teal. Staff 1 top.
- `cloth_work_green`: Cloth: work green. Janitor coveralls (top and bottom).
- `eye_black`: Face: eyes and eyebrows.
- `glasses`: Glasses: dark frames (Assistant Scientist).
- `glow_cyan`: Glow: cyan. Screens and console lights (the only things that bloom). Lower emission_energy_multiplier to make it dimmer.
- `glow_orange`: Glow: orange. Small orange lights. Lower emission_energy_multiplier to make it dimmer.
- `gold_trim`: Gold: the General's cap band and badge.
- `hair_brown`: Hair: neat brown (Student).
- `hair_gray`: Hair: gray. The General and Janitor mustaches.
- `hair_pale`: Hair: pale gray-white (Assistant Scientist).
- `mouth_dark`: Face: the dark mouth.
- `room_console_navy`: Room: navy. Colours the console bodies and the chairs.
- `room_door_void`: Room: pure black, not lit. The dark hole you see when the door slides open.
- `room_floor_navy`: Room: navy. Colours the lower floor.
- `room_panel_cream`: Room: cream. Colours wall panels and trim.
- `room_rocket_white`: Room: warm white. Colours the rocket outside the window.
- `room_table_navy`: Room: deep navy. Colours the table top and the screen frames.
- `room_trim_dark`: Room: dark gray. Colours the door, the supply closet and the launch tower.
- `room_walkway_gray`: Room: gray. Colours the walkway, the steps and the railing.
- `room_wall_white`: Room: warm white. Colours the walls.
- `shoe_dark`: Shoes: dark.
- `skin_dark`: Character skin: dark.
- `skin_light`: Character skin: light.
- `skin_medium`: Character skin: medium.
- `glow_cyan_screen`: Cyan screens on the console monitors. A dimmer, darker version of glow_cyan so the monitors read as accents. Change BOTH Albedo > Color and Emission > Color.
- `room_console_top`: The tops of the consoles (a muted cream, darker than room_panel_cream).
