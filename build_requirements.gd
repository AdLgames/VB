extends Node

# --- EDIT THIS FILE TO GROW THE TECH TREE ---
# requirements: building id -> array of building ids that must already be
# BUILT (completed, not just queued) before this one can be queued.
var requirements: Dictionary = {
	"hall": [],
	"farm": ["hall"],
	"lumber_camp": ["hall"],
	"barracks": ["hall"],
}

# max_count: building id -> maximum number that may exist at once
# (completed OR currently queued). Omit an id here for unlimited.
var max_count: Dictionary = {
	"hall": 1,
}

func can_build(building_id: String, completed_ids: Array, pending_ids: Array) -> bool:
	var reqs = requirements.get(building_id, [])
	for req in reqs:
		if not completed_ids.has(req):
			return false

	if max_count.has(building_id):
		var existing = 0
		for id in completed_ids:
			if id == building_id:
				existing += 1
		for id in pending_ids:
			if id == building_id:
				existing += 1
		if existing >= max_count[building_id]:
			return false

	return true
