extends Node

# Each pending item: { "building": Building, "grid_x": int, "grid_y": int, "timer": Timer }
var pending_builds: Array = []

@onready var tile_grid: Node2D = get_parent()
@onready var villager_manager = get_parent().get_node("VillagerManager")
signal villager_assignment_failed

func queue_building(building: Building, grid_x: int, grid_y: int) -> bool:
	if not ResourceManager.spend_resources(building.build_cost):
		return false

	var timer = Timer.new()
	timer.wait_time = building.build_time_seconds
	timer.one_shot = true
	add_child(timer)

	var entry = {
		"building": building,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"timer": timer
	}
	pending_builds.append(entry)

	# Mark the tile as "pending" immediately so it shows greyed out
	tile_grid.grid_data[grid_y][grid_x]["pending_building"] = building
	tile_grid._render_grid()

	timer.timeout.connect(func(): _on_build_complete(entry))
	timer.start()
	return true

func _on_build_complete(entry: Dictionary) -> void:
	var x = entry["grid_x"]
	var y = entry["grid_y"]
	tile_grid.grid_data[y][x]["pending_building"] = null
	tile_grid.grid_data[y][x]["occupied_by"] = entry["building"]
	tile_grid._render_grid()

	if entry["building"].id == "hall":
		ResourceManager.population = GameConfig.hall_starter_population
		ResourceManager.resources_changed.emit()

	if entry["building"].type == Building.BuildingType.RESOURCE:
		if not villager_manager.assign_villager(x, y):
			villager_assignment_failed.emit()

	pending_builds.erase(entry)
	entry["timer"].queue_free()
	
	if entry["building"].type == Building.BuildingType.RESOURCE:
			if not villager_manager.assign_villager(x, y):
				villager_assignment_failed.emit()	
