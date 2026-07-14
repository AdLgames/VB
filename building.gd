extends Resource
class_name Building

enum BuildingType { RESOURCE, POPULATION, MILITARY }

@export var id: String
@export var display_name: String
@export var letter: String  # single char shown on the grid
@export var build_cost: Dictionary = {}  # e.g. {"wood": 50}
@export var build_time_seconds: float = 5.0
@export var type: BuildingType

# Only relevant for RESOURCE buildings
@export var output_resource: String = ""
@export var output_amount_per_tick: int = 0

# Only relevant for POPULATION buildings
@export var population_cap_bonus: int = 0  # Farm uses this
