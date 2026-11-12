# Material library

Every 3D thing in the intro cutscene and the character lineup (the room and the people) uses one of these
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
- `accent_cyan`: Accent: cyan, NOT glowing. Small flat cyan parts: General's cyan medal, headset microphone tip, a pen.
- `accent_orange`: Accent: orange, NOT glowing. The door stripe, the map marker, the General's orange medal, a pen, the Student's sneaker stripe.
- `cloth_light_blue`: Cloth: light blue (#9CC4E4). Commander shirt (top).
- `cloth_cyan_gray`: Cloth: cyan-gray (#5FA7AD). Assistant Scientist trousers (bottom) and the Student's backpack and straps.
- `cloth_dark_gray`: Cloth: dark gray (#4A505A). Commander and Staff trousers, the General's belt, headset bands.
- `cloth_general_top`: Cloth: General jacket (top).
- `cloth_labcoat_white`: Cloth: white lab coat. Assistant Scientist top, the Commander's ID badge, the clipboard paper, the mop head.
- `cloth_mustard`: Cloth: mustard. Staff 2 top.
- `cloth_navy`: Cloth: navy. General trousers, Student trousers, General cap.
- `cloth_orange_hoodie`: Cloth: orange. Student hoodie (top).
- `cloth_slate`: Cloth: slate blue. Staff 3 top.
- `cloth_teal`: Cloth: teal (#4A8F8C). Staff 1 top and the Assistant Scientist's shirt (the strip you see under the open coat).
- `cloth_work_green`: Cloth: work green (#6F8A5B). Janitor overalls (trousers, bib, straps) and work cap.
- `eye_black`: Face: eyes and eyebrows.
- `glasses`: Glasses: dark frames (Assistant Scientist).
- `glow_cyan`: Glow: cyan. Screens and console lights (the only things that bloom). Lower emission_energy_multiplier to make it dimmer.
- `glow_orange`: Glow: orange. Small orange lights. Lower emission_energy_multiplier to make it dimmer.
- `gold_trim`: Gold: the General's cap band, buckle, shoulder boards and gold medal.
- `hair_brown`: Hair: brown (#5B3A26). Commander, Staff 1, Staff 3 and Student hair.
- `hair_gray`: Hair: gray (#9AA0A6). The General and Janitor mustaches, Staff 2 hair.
- `hair_pale`: Hair: pale gray-white (#D8D8D8). Assistant Scientist tufts.
- `mouth_dark`: Face: the dark mouth. Only shown on the front, while the lid is open.
- `room_console_navy`: Room: navy. Colours the console bodies and the chairs.
- `room_door_void`: Room: pure black, not lit. The dark hole you see when the door slides open.
- `room_floor_navy`: Room: navy. Colours the lower floor.
- `room_panel_cream`: Room: cream. Colours wall panels and trim.
- `room_rocket_white`: Room: warm white. Colours the rocket outside the window.
- `room_table_navy`: Room: deep navy. Colours the table top and the screen frames.
- `room_trim_dark`: Room: dark gray. Colours the door, the supply closet and the launch tower.
- `room_walkway_gray`: Room: gray. Colours the walkway, the steps and the railing.
- `room_wall_white`: Room: warm white. Colours the walls.
- `shoe_dark`: Boots: dark gray (#4A505A). Everybody except the Student.
- `skin_dark`: Character skin: dark.
- `skin_light`: Character skin: light.
- `skin_medium`: Character skin: medium.
- `glow_cyan_screen`: Cyan screens on the console monitors. A dimmer, darker version of glow_cyan so the monitors read as accents. Change BOTH Albedo > Color and Emission > Color.
- `room_console_top`: The tops of the consoles (a muted cream, darker than room_panel_cream).
- `cloth_cream`: Cloth: cream (#D9D0BF). Janitor shirt (top) and the scientist's coat pocket.
- `shoe_white`: Shoes: warm white (#F2EBDD). The Student's sneakers.
- `prop_wood_brown`: Prop: brown wood (#5B3A26). The clipboard board and the mop handle.
