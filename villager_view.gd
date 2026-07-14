extends Node2D

@onready var tile_grid: Node2D = get_parent()
@onready var villager_manager = get_parent().get_node("VillagerManager")

var path_layer: Node2D
var villager_layer: Node2D

var path_lines: Array = []
var villager_labels: Array = []

func _ready():
	path_layer = Node2D.new()
	villager_layer = Node2D.new()
	add_child(path_layer)
	add_child(villager_layer)

func _process(_delta):
	_update_path_lines()
	_update_villager_labels()

func _update_path_lines() -> void:
	var active_villagers: Array = []
	for v in villager_manager.villagers:
		if v["state"] == "to_resource" or v["state"] == "to_hall":
			active_villagers.append(v)

	while path_lines.size() < active_villagers.size():
		var line = Line2D.new()
		line.width = 3.0
		line.default_color = Color(0.3, 0.6, 1.0, 0.7)
		path_layer.add_child(line)
		path_lines.append(line)

	while path_lines.size() > active_villagers.size():
		path_lines.pop_back().queue_free()

	if not GameConfig.show_villager_paths:
		for line in path_lines:
			line.visible = false
		return

	for i in range(active_villagers.size()):
		var v = active_villagers[i]
		var line = path_lines[i]
		line.visible = true
		line.clear_points()

		# Start the line from the villager's current position, not the
		# original path start, so it visibly shortens as they walk it.
		line.add_point(tile_grid.grid_display.position + v["pos"] * tile_grid.cell_size + Vector2(tile_grid.cell_size, tile_grid.cell_size) / 2)
		for j in range(v["path_index"], v["path"].size()):
			var tile = v["path"][j]
			line.add_point(tile_grid.grid_display.position + tile * tile_grid.cell_size + Vector2(tile_grid.cell_size, tile_grid.cell_size) / 2)

func _update_villager_labels() -> void:
	var villagers = villager_manager.villagers

	while villager_labels.size() < villagers.size():
		var label = Label.new()
		label.text = "v"
		label.add_theme_color_override("font_color", Color(1, 1, 0))
		villager_layer.add_child(label)
		villager_labels.append(label)

	while villager_labels.size() > villagers.size():
		villager_labels.pop_back().queue_free()

	for i in range(villagers.size()):
		var v = villagers[i]
		var label = villager_labels[i]
		label.add_theme_font_size_override("font_size", int(tile_grid.cell_size * 0.5))
		label.position = tile_grid.grid_display.position + v["pos"] * tile_grid.cell_size
		
		
		
