extends Node
class_name JobManagerClass

const AUTO_GATHER_INTERVAL := 3

var jobs: Array[Dictionary] = []
var _auto_non_resource_jobs_since_gather: int = 0

@onready var _inventory_manager: Node = get_node("/root/InventoryManager")

func add_job(type: String, target_pos: Vector2i, extra_data: Dictionary = {}) -> void:
	if type != GameData.JOB_FETCH_ANIMAL:
		for job in jobs:
			if job.target_pos == target_pos and job.type == type:
				return

	var job_dict := {
		"type": type,
		"target_pos": target_pos,
	}
	job_dict.merge(extra_data)
	jobs.append(job_dict)

func _pop_job_at(index: int) -> Dictionary:
	var selected_job: Dictionary = jobs[index]
	jobs.remove_at(index)
	return selected_job

func _find_first_job_index(prefer_non_resource: bool) -> int:
	if jobs.is_empty():
		return -1
	if not prefer_non_resource:
		return 0
	for index in range(jobs.size()):
		if String(jobs[index].get("type", "")) != GameData.JOB_GATHER_RESOURCE:
			return index
	return 0

func _find_first_resource_job_index() -> int:
	for index in range(jobs.size()):
		if String(jobs[index].get("type", "")) == GameData.JOB_GATHER_RESOURCE:
			return index
	return -1

func _get_job_related_item_type(job: Dictionary) -> String:
	var output_item_type: String = String(job.get("output_item_type", ""))
	if output_item_type != "":
		return output_item_type
	var target_item_type: String = String(job.get("target_item_type", ""))
	if target_item_type != "":
		return target_item_type
	return String(job.get("item_type", ""))

func _get_base_job_priority(job: Dictionary) -> int:
	var job_type: String = String(job.get("type", ""))
	match job_type:
		GameData.JOB_HARVEST:
			return 140
		GameData.JOB_COLLECT_ANIMAL_PRODUCT, GameData.JOB_PROCESSOR_COLLECT:
			return 130
		GameData.JOB_FEED_ANIMAL, GameData.JOB_PROCESSOR_DELIVER:
			return 120
		GameData.JOB_WATER:
			return 110
		GameData.JOB_PLANT:
			return 100
		GameData.JOB_TILL:
			return 90
		GameData.JOB_FETCH_ANIMAL:
			return 85
		GameData.JOB_GATHER_RESOURCE:
			return 70
		GameData.JOB_DELIVER:
			return 60
		_:
			return 50

func _get_target_bonus(job: Dictionary) -> int:
	if _inventory_manager == null:
		return 0
	var item_type: String = _get_job_related_item_type(job)
	if item_type == "":
		return 0
	var shortage: int = _inventory_manager.get_item_shortage(item_type)
	if shortage <= 0:
		return 0
	return 1000 + min(shortage, 999)

func _get_job_priority(job: Dictionary) -> int:
	return _get_base_job_priority(job) + _get_target_bonus(job)

func _get_job_anchor_cell(job: Dictionary) -> Vector2i:
	if job.has("interaction_pos"):
		return Vector2i(job.get("interaction_pos", job.target_pos))
	if job.has("storage_pos"):
		return Vector2i(job.get("storage_pos", job.target_pos))
	return Vector2i(job.get("target_pos", Vector2i.ZERO))

func _get_job_distance_from_worker(worker: FarmWorker, job: Dictionary) -> int:
	if worker == null:
		return 0
	var worker_cell := Vector2i(round(worker.position.x / GameData.TILE_SIZE), round(worker.position.y / GameData.TILE_SIZE))
	var anchor_cell: Vector2i = _get_job_anchor_cell(job)
	return abs(worker_cell.x - anchor_cell.x) + abs(worker_cell.y - anchor_cell.y)

func get_next_job() -> Dictionary:
	if jobs.is_empty():
		return {}

	var best_index: int = -1
	var best_priority: int = -1000000
	for index in range(jobs.size()):
		var priority: int = _get_job_priority(jobs[index])
		if best_index < 0 or priority > best_priority:
			best_index = index
			best_priority = priority

	if best_index < 0:
		return {}

	var selected_job: Dictionary = jobs[best_index]
	var job_type: String = String(selected_job.get("type", ""))
	if job_type == GameData.JOB_GATHER_RESOURCE:
		_auto_non_resource_jobs_since_gather = 0
	else:
		_auto_non_resource_jobs_since_gather += 1
	return _pop_job_at(best_index)

func get_next_job_for_worker(worker: FarmWorker) -> Dictionary:
	if jobs.is_empty():
		return {}
	if worker == null:
		return get_next_job()

	var best_index: int = -1
	var best_priority: int = -1000000
	var best_distance: int = 1000000
	for index in range(jobs.size()):
		var job: Dictionary = jobs[index]
		if not worker.matches_job(job):
			continue
		var priority: int = _get_job_priority(job)
		var distance: int = _get_job_distance_from_worker(worker, job)
		if best_index < 0 or priority > best_priority or (priority == best_priority and distance < best_distance):
			best_index = index
			best_priority = priority
			best_distance = distance

	if best_index < 0:
		return {}

	var selected_job: Dictionary = jobs[best_index]
	var job_type: String = String(selected_job.get("type", ""))
	if job_type == GameData.JOB_GATHER_RESOURCE:
		_auto_non_resource_jobs_since_gather = 0
	else:
		_auto_non_resource_jobs_since_gather += 1
	return _pop_job_at(best_index)

func has_job_at(target_pos: Vector2i) -> bool:
	for job in jobs:
		if job.target_pos == target_pos:
			return true
	return false
