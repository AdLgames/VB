extends Node

# --- EDIT THIS FILE TO TUNE STARTING VALUES ---
# Building costs/build times live in their own .tres files under res://buildings/
# (edit those directly in the Inspector). This file covers everything else.

# Starting resources (before any Hall is built)
@export var starting_wood: int = 60
@export var starting_clay: int = 0
@export var starting_iron: int = 0
@export var starting_population: int = 0
@export var starting_population_cap: int = 3

# Population granted the moment the Hall completes
@export var hall_starter_population: int = 3

# Spearman training
@export var spearman_wood_cost: int = 25
@export var spearman_population_cost: int = 1
@export var spearman_train_time: float = 6.0

# Villager behavior
@export var villager_speed: float = 1.5       # tiles per second
@export var villager_collect_time: float = 2.0  # seconds spent gathering
@export var villager_carry_amount: int = 5     # resource delivered per trip
@export var max_villagers_per_tile: int = 3

# Production tick rate (also drives UI refresh)
@export var tick_seconds: float = 0.5

# Starting tile layout — counts of each resource tile scattered on the grid.
# Anything left over after placing these stays "empty".
@export var starting_forest_tiles: int = 3
@export var starting_clay_tiles: int = 2
@export var starting_iron_tiles: int = 2

@export var forest_resource_amount: int = 50
@export var clay_resource_amount: int = 40
@export var iron_resource_amount: int = 30

@export var show_villager_paths: bool = true
