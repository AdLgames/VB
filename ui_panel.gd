extends Control

@onready var tile_grid: Node2D = get_parent()
@onready var build_queue = tile_grid.get_node("BuildQueue")

@onready var stats_panel: PanelContainer = $StatsPanel
@onready var build_panel: PanelContainer = $BuildPanel
@onready var train_panel: PanelContainer = $TrainPanel

@onready var stats_box: HBoxContainer = $StatsPanel/StatsBox
@onready var wood_label: Label = $StatsPanel/StatsBox/WoodLabel
@onready var clay_label: Label = $StatsPanel/StatsBox/ClayLabel
@onready var iron_label: Label = $StatsPanel/StatsBox/IronLabel
@onready var pop_label: Label = $StatsPanel/StatsBox/PopulationLabel
@onready var army_label: Label = $StatsPanel/StatsBox/ArmyLabel
@onready var status_label: Label = $StatsPanel/StatsBox/StatusLabel

@onready var build_buttons_box: VBoxContainer = $BuildPanel/BuildButtonsBox
@onready var queue_box: VBoxContainer = $QueueBox
@onready var hall_button: Button = $BuildPanel/BuildButtonsBox/HallButton
@onready var farm_button: Button = $BuildPanel/BuildButtonsBox/FarmButton
@onready var lumber_button: Button = $BuildPanel/BuildButtonsBox/LumberButton
@onready var barracks_button: Button = $BuildPanel/BuildButtonsBox/BarracksButton

@onready var train_button: Button = $TrainPanel/TrainSpearmanButton

@onready var villager_manager = tile_grid.get_node("VillagerManager")
@onready var villager_panel: Control = $VillagerPanel
@onready var villager_info_label: Label = $VillagerPanel/VillagerInfoLabel
@onready var villager_plus_button: Button = $VillagerPanel/VillagerButtonsBox/PlusButton
@onready var villager_minus_button: Button = $VillagerPanel/VillagerButtonsBox/MinusButton
@onready var villager_close_button: Button = $VillagerPanel/CloseButton

@onready var save_button: Button = $SaveButton
@onready var save_manager = tile_grid.get_node("SaveManager")


var selected_tile: Vector2 = Vector2(-1, -1)


var hall_res = load("res://buildings/hall.tres")
var farm_res = load("res://buildings/farm.tres")
var lumber_res = load("res://buildings/lumber_camp.tres")
var barracks_res = load("res://buildings/barracks.tres")

func _ready():
	ResourceManager.resources_changed.connect(_refresh_ui)
	ArmyManager.army_changed.connect(_refresh_ui)
	tile_grid.tile_tapped.connect(_on_tile_tapped)

	hall_button.pressed.connect(func(): _start_placing(hall_res))
	farm_button.pressed.connect(func(): _start_placing(farm_res))
	lumber_button.pressed.connect(func(): _start_placing(lumber_res))
	barracks_button.pressed.connect(func(): _start_placing(barracks_res))
	train_button.pressed.connect(_on_train_pressed)
	villager_plus_button.pressed.connect(_on_villager_plus)
	villager_minus_button.pressed.connect(_on_villager_minus)
	villager_close_button.pressed.connect(_hide_villager_panel)
	add_to_group("ui_refresh")
	build_queue.villager_assignment_failed.connect(func(): status_label.text = "No free population to staff new building.")
	save_button.pressed.connect(func(): save_manager.save_game())
	_layout_ui()
	_refresh_ui()

# Finds the first empty tile and queues the building there.
# Good enough for the prototype — later this becomes "tap a tile to place".
func _start_placing(building: Building) -> void:
	if not ResourceManager.can_afford(building.build_cost):
		return
	var completed = tile_grid.get_completed_building_ids()
	var pending = tile_grid.get_pending_building_ids()
	if not BuildRequirements.can_build(building.id, completed, pending):
		status_label.text = "Requirements not met for " + building.display_name
		return
	tile_grid.placing_building = building
	status_label.text = "Tap an empty tile to place: " + building.display_name
	
	
func _on_tile_tapped(grid_x: int, grid_y: int) -> void:
	var cell = tile_grid.grid_data[grid_y][grid_x]
	var building = cell["occupied_by"]

	if tile_grid.placing_building != null:
		var placing = tile_grid.placing_building
		if not _is_tile_buildable(cell, placing):
			if placing.type == Building.BuildingType.RESOURCE:
				var required_type = {"wood": "forest", "clay": "clay", "iron": "iron"}.get(placing.output_resource, "")
				status_label.text = placing.display_name + " must be built on a " + required_type + " tile."
			else:
				status_label.text = "Can't build there — pick an empty tile."
			return
		if build_queue.queue_building(placing, grid_x, grid_y):
			status_label.text = ""
			tile_grid.placing_building = null
			_refresh_ui()
		return

	var is_deposit_tile = cell["type"] == "forest" or cell["type"] == "clay" or cell["type"] == "iron"
	if (building != null and building.type == Building.BuildingType.RESOURCE) or (building == null and is_deposit_tile):
		selected_tile = Vector2(grid_x, grid_y)
		villager_panel.visible = true
		_refresh_villager_panel()
	else:
		_hide_villager_panel()

func _is_tile_buildable(cell: Dictionary, building: Building) -> bool:
	if cell["occupied_by"] != null:
		return false
	if cell["pending_building"] != null:
		return false
	if building.type == Building.BuildingType.RESOURCE:
		var required_type = {"wood": "forest", "clay": "clay", "iron": "iron"}.get(building.output_resource, "")
		return cell["type"] == required_type
	else:
		return cell["type"] == "empty"

func _on_train_pressed() -> void:
	ArmyManager.train_spearman()
	_refresh_ui()

func _refresh_ui() -> void:
	wood_label.text = "Wood: " + str(ResourceManager.wood)
	clay_label.text = "Clay: " + str(ResourceManager.clay)
	iron_label.text = "Iron: " + str(ResourceManager.iron)
	pop_label.text = "Population: " + str(ResourceManager.population) + " / " + str(ResourceManager.population_cap)
	army_label.text = "Army: " + str(ArmyManager.army_count)

	var completed = tile_grid.get_completed_building_ids()
	var pending = tile_grid.get_pending_building_ids()
	hall_button.disabled = not ResourceManager.can_afford(hall_res.build_cost) or not BuildRequirements.can_build("hall", completed, pending)
	farm_button.disabled = not ResourceManager.can_afford(farm_res.build_cost) or not BuildRequirements.can_build("farm", completed, pending)
	lumber_button.disabled = not ResourceManager.can_afford(lumber_res.build_cost) or not BuildRequirements.can_build("lumber_camp", completed, pending)
	barracks_button.disabled = not ResourceManager.can_afford(barracks_res.build_cost) or not BuildRequirements.can_build("barracks", completed, pending)
	_refresh_queue_display()

func _refresh_queue_display() -> void:
	for child in queue_box.get_children():
		child.queue_free()
	for entry in build_queue.pending_builds:
		var label = Label.new()
		var time_left = entry["timer"].time_left
		label.text = entry["building"].display_name + ": " + str(int(time_left)) + "s"
		queue_box.add_child(label)

func _layout_ui() -> void:
	var vp = get_viewport_rect().size
	stats_panel.position = Vector2(20, 10)
	build_panel.position = Vector2(20, 70)
	train_panel.position = Vector2(20, 420)
	villager_panel.position = Vector2(vp.x / 2 - 150, 20)
	queue_box.position = Vector2(20, 340)
	save_button.position = Vector2(20, 560)
	
func _refresh_villager_panel() -> void:
	if selected_tile.x < 0:
		return
	var cell = tile_grid.grid_data[selected_tile.y][selected_tile.x]
	var building = cell["occupied_by"]
	var remaining = cell["resource_amount"]

	if building != null:
		var count = villager_manager.count_villagers_at(selected_tile.x, selected_tile.y)
		villager_info_label.text = building.display_name + " — Villagers: " + str(count) + " / " + str(villager_manager.MAX_VILLAGERS_PER_TILE) + "\nRemaining: " + str(remaining)
		villager_plus_button.visible = true
		villager_minus_button.visible = true
		villager_plus_button.disabled = count >= villager_manager.MAX_VILLAGERS_PER_TILE or ResourceManager.population <= 0
		villager_minus_button.disabled = count <= 0
	else:
		villager_info_label.text = cell["type"].capitalize() + " deposit — Remaining: " + str(remaining)
		villager_plus_button.visible = false
		villager_minus_button.visible = false

func _on_villager_plus() -> void:
	if not villager_manager.assign_villager(selected_tile.x, selected_tile.y):
		status_label.text = "Can't assign — check population or tile cap."
	_refresh_villager_panel()

func _on_villager_minus() -> void:
	villager_manager.remove_villager(selected_tile.x, selected_tile.y)
	_refresh_villager_panel()

func _hide_villager_panel() -> void:
	villager_panel.visible = false
	selected_tile = Vector2(-1, -1)
