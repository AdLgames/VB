extends Node

signal army_changed

var army_count: int = 0

# training_queue holds entries: { "timer": Timer }
var training_queue: Array = []

var SPEARMAN_COST: Dictionary
var SPEARMAN_POP_COST: int
var SPEARMAN_TRAIN_TIME: float

func _ready():
	SPEARMAN_COST = {"wood": GameConfig.spearman_wood_cost}
	SPEARMAN_POP_COST = GameConfig.spearman_population_cost
	SPEARMAN_TRAIN_TIME = GameConfig.spearman_train_time

func train_spearman() -> bool:
	if ResourceManager.population < SPEARMAN_POP_COST:
		return false  # not enough free population
	if not ResourceManager.spend_resources(SPEARMAN_COST):
		return false  # not enough wood

	ResourceManager.population -= SPEARMAN_POP_COST
	ResourceManager.resources_changed.emit()

	var timer = Timer.new()
	timer.wait_time = SPEARMAN_TRAIN_TIME
	timer.one_shot = true
	add_child(timer)

	var entry = {"timer": timer}
	training_queue.append(entry)

	timer.timeout.connect(func(): _on_training_complete(entry))
	timer.start()
	return true

func _on_training_complete(entry: Dictionary) -> void:
	army_count += 1
	army_changed.emit()
	training_queue.erase(entry)
	entry["timer"].queue_free()
