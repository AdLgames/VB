extends Node

# Emitted whenever any resource or population value changes,
# so UI can just listen instead of polling every frame.
signal resources_changed

var wood: int
var clay: int
var iron: int
var population: int
var population_cap: int

func _ready():
	wood = GameConfig.starting_wood
	clay = GameConfig.starting_clay
	iron = GameConfig.starting_iron
	population = GameConfig.starting_population
	population_cap = GameConfig.starting_population_cap
	
func add_resource(type: String, amount: int) -> void:
	match type:
		"wood": wood += amount
		"clay": clay += amount
		"iron": iron += amount
	resources_changed.emit()

func can_afford(cost_dict: Dictionary) -> bool:
	for resource_type in cost_dict:
		var have = get(resource_type)
		if have < cost_dict[resource_type]:
			return false
	return true

func spend_resources(cost_dict: Dictionary) -> bool:
	if not can_afford(cost_dict):
		return false
	for resource_type in cost_dict:
		set(resource_type, get(resource_type) - cost_dict[resource_type])
	resources_changed.emit()
	return true
