# Textures.gd
# Makes every texture in the game with code: no image files, no downloads.
# Each texture is a RECIPE in game_data.json ("textures"), for example:
#     "floor": { "pattern": "grid", "pixels": 256, "squares_across": 4, ... }
#
# The textures are GRAY. Godot multiplies a material's texture by its color,
# so the same gray grid on a blue material gives a blue grid. That way the
# colors stay where they already were (the scenes and the "look" sections).
#
# Like Data and GameState, this is an autoload. Any script can call:
#     Textures.apply(material, "floor")
extends Node

# Textures already made, so each one is drawn only once. { "floor": <texture> }
var made: Dictionary = {}


# Puts the texture named `recipe_name` on a material.
# world = true: the pattern is measured in the WORLD (good for floors and
# walls: every tile is the same size, however big the box is).
func apply(material: StandardMaterial3D, recipe_name: String, world: bool = false) -> void:
	var recipe: Dictionary = Data.game_data["textures"][recipe_name]
	material.albedo_texture = get_texture(recipe_name)

	# "Triplanar" = project the texture from the 3 directions (top, front, side),
	# so it works on any shape without unwrapping it.
	material.uv1_triplanar = true
	material.uv1_world_triplanar = world
	# One copy of the texture covers `meters` meters.
	material.uv1_scale = Vector3.ONE / recipe["meters"]

	# Optional shine settings in the recipe.
	if recipe.has("metallic"):
		material.metallic = recipe["metallic"]
	if recipe.has("roughness"):
		material.roughness = recipe["roughness"]


func get_texture(recipe_name: String) -> ImageTexture:
	if not made.has(recipe_name):
		made[recipe_name] = make_texture(Data.game_data["textures"][recipe_name])
	return made[recipe_name]


# Draws one texture, one pixel at a time.
func make_texture(recipe: Dictionary) -> ImageTexture:
	var size: int = int(recipe["pixels"])
	var image := Image.create(size, size, false, Image.FORMAT_RGB8)
	var noise := make_noise(recipe, size)

	for y in size:
		for x in size:
			# n = a random-looking bump from -0.5 to 0.5, the same every run.
			var n: float = noise.get_pixel(x, y).r - 0.5
			var brightness: float
			match recipe["pattern"]:
				"grid":
					brightness = grid_pixel(recipe, x, y, n)
				"crinkle":
					brightness = recipe["base"] + recipe["strength"] * n
				"weave":
					brightness = weave_pixel(recipe, x, y, n)
			image.set_pixel(x, y, Color(brightness, brightness, brightness))

	# Mipmaps = smaller copies, so the texture doesn't shimmer far away.
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


# Noise = smooth random bumps. "Seamless" means the right edge matches the
# left edge, so the texture repeats with no visible seam.
# The seed comes from the data file, so the bumps are the same every time.
func make_noise(recipe: Dictionary, size: int) -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = Data.game_data["textures"]["seed"]
	noise.frequency = recipe["noise_frequency"]
	if recipe["pattern"] == "crinkle":
		noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED   # sharp creases, like foil
	return noise.get_seamless_image(size, size)


# Squares with lines between them (floor tiles, wall panels, solar cells).
# rivet_pixels > 0 adds a round dot near each corner of every square.
func grid_pixel(recipe: Dictionary, x: int, y: int, n: float) -> float:
	var square: int = int(recipe["pixels"] / recipe["squares_across"])
	var sx: int = x % square   # where we are inside this square
	var sy: int = y % square
	var half_line: int = int(recipe["line_pixels"] / 2.0)

	# Near any edge of the square? Then this pixel is part of a line.
	if sx < half_line or sx >= square - half_line or sy < half_line or sy >= square - half_line:
		return recipe["line"]

	# Rivets: the distance to the nearest corner dot.
	var rivet: int = int(recipe["rivet_pixels"])
	if rivet > 0:
		var inset: int = int(recipe["rivet_inset"])
		var dx: int = mini(absi(sx - inset), absi(sx - (square - inset)))
		var dy: int = mini(absi(sy - inset), absi(sy - (square - inset)))
		if dx * dx + dy * dy <= rivet * rivet:
			return recipe["rivet"]

	return recipe["base"] + recipe["speckle"] * n


# Over-under threads, like cloth: a checkerboard of thread_pixels squares,
# one a bit lighter, the next a bit darker.
func weave_pixel(recipe: Dictionary, x: int, y: int, n: float) -> float:
	var thread: float = recipe["thread_pixels"]
	var over: bool = (floori(x / thread) + floori(y / thread)) % 2 == 0
	var shade: float = recipe["weave"] if over else -recipe["weave"]
	return recipe["base"] + shade + recipe["speckle"] * n
