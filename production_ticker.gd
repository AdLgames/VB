extends Node

@onready var tile_grid: Node2D = get_parent()
@onready var tick_timer: Timer = $TickTimer


func _ready():
	tick_timer.timeout.connect(_on_tick)
	tick_timer.wait_time = GameConfig.tick_seconds
	
func _on_tick():
	_grow_population()
	get_tree().call_group("ui_refresh", "_refresh_ui")

# Loop every tile; if it has a RESOURCE building, add its output.
func _produce_resources():
	for y in range(tile_grid.GRID_HEIGHT):
		for x in range(tile_grid.GRID_WIDTH):
			var building = tile_grid.grid_data[y][x]["occupied_by"]
			if building != null and building.type == Building.BuildingType.RESOURCE:
				ResourceManager.add_resource(building.output_resource, building.output_amount_per_tick)

# If any Hall is placed, grow population by 1/tick until it hits the cap.
func _grow_population():
	var has_hall = false
	for y in range(tile_grid.GRID_HEIGHT):
		for x in range(tile_grid.GRID_WIDTH):
			var building = tile_grid.grid_data[y][x]["occupied_by"]
			if building != null and building.id == "hall":
				has_hall = true

	if has_hall and ResourceManager.population < ResourceManager.population_cap:
		ResourceManager.population += 1
		ResourceManager.resources_changed.emit()
