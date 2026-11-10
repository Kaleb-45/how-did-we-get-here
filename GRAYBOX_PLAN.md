Next task: a graybox ship interior. Same step-and-check system.

A graybox is a rough layout with plain boxes, no art. The player walks through it in first person, the same as the hangar.

Layout:
- One main hallway with four rooms: Bridge, Power room, Science bay, Comms room.
- Bridge: the player starts here. A wall screen shows the full dashboard.
- Power room: move the Reroute Power station here. It must work exactly as it does now.
- Science bay and Comms room: one empty station spot each, marked with a glowing floor marker and a label ("Future station: Data", "Future station: Comms").
- Each room shows the part version the player chose (for example, a bigger panel visible through the Power room window).
- Room names and labels go in a data file, not in code.

Steps:
1. Read the current walk scene. Tell me what moves to the new ship and what stays. Change no files.
2. Build the hallway and four empty rooms. I can walk through all of them.
3. Add room labels and the floor markers for future stations.
4. Move the Reroute Power station into the Power room and confirm the storm still works.
5. Show the chosen part versions in each room.
6. Add the dashboard wall screen on the Bridge.
7. Full playthrough, then re-export to build/web and test in the browser.
Start with step 1 only.
