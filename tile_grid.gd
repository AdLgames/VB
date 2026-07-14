extends Node2D

const GRID_WIDTH = 10
const GRID_HEIGHT = 10

var grid_data = []
var cell_size: float = 60.0
var placing_building: Building = null  # set when a build button is tapped, cleared on placement
var astar_grid: AStarGrid2D = AStarGrid2D.new()
signal tile_tapped(grid_x, grid_y)


const TILE_CHARS = {
	"empty": ".",
	"forest": "F",
	"clay": "C",
	"iron": "^",
	"hall_slot": "H"
}

@onready var grid_display: GridContainer = $GridDisplay

func _ready():
	grid_display.columns = GRID_WIDTH
	_layout_grid()

func _enter_tree() -> void:
	_init_grid_data()
	_setup_astar()
	
func _init_grid_data() -> void:
	for y in range(GRID_HEIGHT):
		var row = []
		for x in range(GRID_WIDTH):
			row.append({ "type": "empty", "occupied_by": null, "pending_building": null, "resource_amount": 0 })
		grid_data.append(row)

	var all_positions: Array = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			all_positions.append(Vector2i(x, y))
	all_positions.shuffle()

	_place_random_tiles("forest", GameConfig.starting_forest_tiles, all_positions)
	_place_random_tiles("clay", GameConfig.starting_clay_tiles, all_positions)
	_place_random_tiles("iron", GameConfig.starting_iron_tiles, all_positions)
	
	
# Pops positions off the front of the shared shuffled pool so different
# tile types never land on the same spot.
func _place_random_tiles(tile_type: String, count: int, position_pool: Array) -> void:
	var amount_by_type = {
		"forest": GameConfig.forest_resource_amount,
		"clay": GameConfig.clay_resource_amount,
		"iron": GameConfig.iron_resource_amount
	}
	for i in range(count):
		if position_pool.is_empty():
			return
		var pos = position_pool.pop_front()
		grid_data[pos.y][pos.x]["type"] = tile_type
		grid_data[pos.y][pos.x]["resource_amount"] = amount_by_type[tile_type]
		
		
# Sizes the grid to fill most of the screen, then centers it.
func _layout_grid() -> void:
	var vp = get_viewport_rect().size
	cell_size = (min(vp.x, vp.y) * 0.7) / GRID_WIDTH
	_render_grid()
	var grid_w = GRID_WIDTH * cell_size
	var grid_h = GRID_HEIGHT * cell_size
	grid_display.position = Vector2((vp.x - grid_w) / 2, (vp.y - grid_h) / 2)

func _render_grid():
	for child in grid_display.get_children():
		child.queue_free()

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell = grid_data[y][x]
			var label = Label.new()
			label.text = _get_display_char(cell)
			label.add_theme_font_size_override("font_size", int(cell_size * 0.6))
			label.custom_minimum_size = Vector2(cell_size, cell_size)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if cell["pending_building"] != null:
				label.modulate = Color(0.5, 0.5, 0.5)  # greyed out while queued
			grid_display.add_child(label)

func _get_display_char(cell: Dictionary) -> String:
	if cell["occupied_by"] != null:
		return cell["occupied_by"].letter
	if cell["pending_building"] != null:
		return cell["pending_building"].letter
	return TILE_CHARS[cell["type"]]

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)

func _handle_tap(screen_pos: Vector2) -> void:
	var local_pos = screen_pos - grid_display.position
	if local_pos.x < 0 or local_pos.y < 0:
		return
	var grid_x = int(local_pos.x / cell_size)
	var grid_y = int(local_pos.y / cell_size)
	if grid_x >= 0 and grid_x < GRID_WIDTH and grid_y >= 0 and grid_y < GRID_HEIGHT:
		tile_tapped.emit(grid_x, grid_y)




func get_hall_position():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var b = grid_data[y][x]["occupied_by"]
			if b != null and b.id == "hall":
				return Vector2(x, y)
	return null
	
	
func _setup_astar() -> void:
	astar_grid.region = Rect2i(0, 0, GRID_WIDTH, GRID_HEIGHT)
	astar_grid.cell_size = Vector2(1, 1)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var t = grid_data[y][x]["type"]
			var blocked = t == "forest" or t == "clay" or t == "iron"
			astar_grid.set_point_solid(Vector2i(x, y), blocked)

func get_grid_path(from: Vector2, to: Vector2) -> Array:
	var from_cell = Vector2i(from)
	var to_cell = Vector2i(to)
	var from_was_solid = astar_grid.is_point_solid(from_cell)
	var to_was_solid = astar_grid.is_point_solid(to_cell)

	# Temporarily unlock both ends so a villager can always path away from
	# wherever they're currently standing, and always path onto their
	# destination — even if those tiles are normally solid (built camps).
	if from_was_solid:
		astar_grid.set_point_solid(from_cell, false)
	if to_was_solid:
		astar_grid.set_point_solid(to_cell, false)

	var raw_path = astar_grid.get_point_path(Vector2i(from), Vector2i(to))

	if from_was_solid:
		astar_grid.set_point_solid(from_cell, true)
	if to_was_solid:
		astar_grid.set_point_solid(to_cell, true)

	var result: Array = []
	for p in raw_path:
		result.append(Vector2(p.x, p.y))
	return result

func get_completed_building_ids() -> Array:
	var ids = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var b = grid_data[y][x]["occupied_by"]
			if b != null:
				ids.append(b.id)
	return ids

func get_pending_building_ids() -> Array:
	var ids = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var b = grid_data[y][x]["pending_building"]
			if b != null:
				ids.append(b.id)
	return ids

func set_tile_walkable(grid_x: int, grid_y: int, walkable: bool) -> void:
	astar_grid.set_point_solid(Vector2i(grid_x, grid_y), not walkable)

func deplete_tile(grid_x: int, grid_y: int) -> void:
	var cell = grid_data[grid_y][grid_x]
	cell["occupied_by"] = null
	cell["type"] = "empty"
	cell["resource_amount"] = 0
	set_tile_walkable(grid_x, grid_y, true)
	_render_grid()
