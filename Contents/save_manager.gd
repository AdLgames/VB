extends Node

const SAVE_PATH = "user://savegame.json"

@onready var tile_grid = get_parent()

# Gathers the whole game state into one dictionary, then writes it as JSON.
func save_game() -> void:
	var data = {
		"resources": {
			"wood": ResourceManager.wood,
			"clay": ResourceManager.clay,
			"iron": ResourceManager.iron,
			"population": ResourceManager.population,
			"population_cap": ResourceManager.population_cap
		},
		"army_count": ArmyManager.army_count,
		"tiles": _serialize_tiles(),
		"villagers": _serialize_villagers()
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("Save failed: could not open file")
		return
	file.store_string(JSON.stringify(data))
	file.close()
	print("Game saved to ", SAVE_PATH)

# Tiles: store type, resource amount, and which building id (if any) is on each.
func _serialize_tiles() -> Array:
	var result = []
	for y in range(tile_grid.GRID_HEIGHT):
		for x in range(tile_grid.GRID_WIDTH):
			var cell = tile_grid.grid_data[y][x]
			var building_id = ""
			if cell["occupied_by"] != null:
				building_id = cell["occupied_by"].id
			result.append({
				"x": x,
				"y": y,
				"type": cell["type"],
				"resource_amount": cell["resource_amount"],
				"building_id": building_id
			})
	return result

func _serialize_villagers() -> Array:
	var result = []
	var vm = tile_grid.get_node("VillagerManager")
	for v in vm.villagers:
		result.append({
			"resource_tile_x": int(v["resource_tile"].x),
			"resource_tile_y": int(v["resource_tile"].y),
			"resource_type": v["resource_type"]
		})
	return result
