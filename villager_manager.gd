extends Node

signal villagers_changed

var villagers: Array = []

@onready var tile_grid: Node2D = get_parent()
@export var base_villager_speed: float = 1.5

var COLLECT_TIME: float
var CARRY_AMOUNT: int
var MAX_VILLAGERS_PER_TILE: int

func _ready():
	base_villager_speed = GameConfig.villager_speed
	COLLECT_TIME = GameConfig.villager_collect_time
	CARRY_AMOUNT = GameConfig.villager_carry_amount
	MAX_VILLAGERS_PER_TILE = GameConfig.max_villagers_per_tile

func _process(delta: float) -> void:
	for v in villagers:
		_update_villager(v, delta)
	_cleanup_exhausted()

func _cleanup_exhausted() -> void:
	for i in range(villagers.size() - 1, -1, -1):
		if villagers[i]["state"] == "exhausted":
			villagers.remove_at(i)
			ResourceManager.population += 1
			ResourceManager.resources_changed.emit()
			villagers_changed.emit()
		
func assign_villager(grid_x: int, grid_y: int) -> bool:
	var hall_pos = tile_grid.get_hall_position()
	if hall_pos == null:
		return false
	if ResourceManager.population <= 0:
		return false
	if count_villagers_at(grid_x, grid_y) >= MAX_VILLAGERS_PER_TILE:
		return false
	var building = tile_grid.grid_data[grid_y][grid_x]["occupied_by"]
	if building == null:
		return false

	ResourceManager.population -= 1
	ResourceManager.resources_changed.emit()

	var villager = {
		"pos": hall_pos,
		"resource_tile": Vector2(grid_x, grid_y),
		"state": "to_resource",
		"path": tile_grid.get_grid_path(hall_pos, Vector2(grid_x, grid_y)),
		"path_index": 0,
		"collect_timer": 0.0,
		"resource_type": building.output_resource,
		"speed": base_villager_speed
	}
	villagers.append(villager)
	villagers_changed.emit()
	return true

func remove_villager(grid_x: int, grid_y: int) -> bool:
	for i in range(villagers.size() - 1, -1, -1):
		if villagers[i]["resource_tile"] == Vector2(grid_x, grid_y):
			villagers.remove_at(i)
			ResourceManager.population += 1
			ResourceManager.resources_changed.emit()
			villagers_changed.emit()
			return true
	return false

func count_villagers_at(grid_x: int, grid_y: int) -> int:
	var count = 0
	for v in villagers:
		if v["resource_tile"] == Vector2(grid_x, grid_y):
			count += 1
	return count

func _update_villager(v: Dictionary, delta: float) -> void:
	match v["state"]:
		"idle":
			var hall_pos = tile_grid.get_hall_position()
			if hall_pos != null:
				v["path"] = tile_grid.get_grid_path(v["pos"], v["resource_tile"])
				v["path_index"] = 0
				v["state"] = "to_resource"
		"to_resource":
			if _follow_path(v, delta):
				v["state"] = "collecting"
				v["collect_timer"] = 0.0
		"collecting":
			v["collect_timer"] += delta
			if v["collect_timer"] >= COLLECT_TIME:
				var hall_pos = tile_grid.get_hall_position()
				if hall_pos != null:
					v["path"] = tile_grid.get_grid_path(v["pos"], hall_pos)
					v["path_index"] = 0
					v["state"] = "to_hall"
		"to_hall":
			if _follow_path(v, delta):
				v["state"] = "delivering"
		"delivering":
			ResourceManager.add_resource(v["resource_type"], CARRY_AMOUNT)
			var tile = v["resource_tile"]
			var cell = tile_grid.grid_data[tile.y][tile.x]
			
			if cell["resource_amount"] <= 0:
				tile_grid.deplete_tile(tile.x, tile.y)
				v["state"] = "exhausted"
			else:
				v["path"] = tile_grid.get_grid_path(v["pos"], v["resource_tile"])
				v["path_index"] = 0
				v["state"] = "to_resource"
# Moves along v["path"] one waypoint at a time. Returns true once the final
# waypoint is reached.
func _follow_path(v: Dictionary, delta: float) -> bool:
	if v["path"].is_empty():
		return true
	if v["path_index"] >= v["path"].size():
		return true

	var target = v["path"][v["path_index"]]
	var dir = target - v["pos"]
	var dist = dir.length()
	var step = v["speed"] * delta

	if step >= dist:
		v["pos"] = target
		v["path_index"] += 1
		if v["path_index"] >= v["path"].size():
			return true
	else:
		v["pos"] += dir.normalized() * step
	return false
