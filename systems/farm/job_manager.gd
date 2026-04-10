extends Node
class_name JobManagerClass

signal job_added

var jobs: Array[Dictionary] = []
var _jobs_by_domain: Dictionary = {}

@onready var _inventory_manager: Node = get_node("/root/InventoryManager")

func add_job(type: String, target_pos: Vector2i, extra_data: Dictionary = {}) -> void:
	if type != GameData.JOB_FETCH_ANIMAL:
		for job in jobs:
			if _is_duplicate_job(job, type, target_pos, extra_data):
				return

	var job_dict := {
		"type": type,
		"target_pos": target_pos,
	}
	job_dict.merge(extra_data)
	jobs.append(job_dict)
	_register_job_in_buckets(job_dict)
	job_added.emit()

func _is_duplicate_job(existing_job: Dictionary, type: String, target_pos: Vector2i, extra_data: Dictionary) -> bool:
	if existing_job.target_pos != target_pos or existing_job.type != type:
		return false

	match type:
		GameData.JOB_PROCESSOR_DELIVER, GameData.JOB_PROCESSOR_COLLECT:
			return String(existing_job.get("item_type", "")) == String(extra_data.get("item_type", ""))
		_:
			return true

func _pop_job_at(index: int) -> Dictionary:
	var selected_job: Dictionary = jobs[index]
	jobs.remove_at(index)
	_unregister_job_from_buckets(selected_job)
	return selected_job

func _find_job_index(job: Dictionary) -> int:
	for i in range(jobs.size()):
		if is_same(jobs[i], job):
			return i
	return -1

func _register_job_in_buckets(job: Dictionary) -> void:
	var domains: Array[String] = _get_bucket_domains_for_job(job)
	job["_bucket_domains"] = domains.duplicate()
	for domain_id in domains:
		if not _jobs_by_domain.has(domain_id):
			_jobs_by_domain[domain_id] = []
		var bucket: Array = _jobs_by_domain[domain_id]
		bucket.append(job)

func _rebuild_job_buckets() -> void:
	_jobs_by_domain.clear()
	for job in jobs:
		_register_job_in_buckets(job)

func _unregister_job_from_buckets(job: Dictionary) -> void:
	for domain_id in job.get("_bucket_domains", []):
		var bucket: Array = _jobs_by_domain.get(String(domain_id), [])
		var index: int = bucket.find(job)
		if index >= 0:
			bucket.remove_at(index)
	job.erase("_bucket_domains")

func _get_bucket_domains_for_job(job: Dictionary) -> Array[String]:
	var job_type: String = String(job.get("type", ""))
	var domains: Array[String] = []
	for domain_id in [
		GameData.WORKER_DOMAIN_FARM,
		GameData.WORKER_DOMAIN_GATHERING,
		GameData.WORKER_DOMAIN_FACTORY,
	]:
		if GameData.is_job_type_allowed_for_worker_domain(domain_id, job_type):
			domains.append(domain_id)

	if job_type in [GameData.JOB_PROCESSOR_DELIVER, GameData.JOB_PROCESSOR_COLLECT, GameData.JOB_FETCH_ANIMAL]:
		if not domains.has(GameData.WORKER_DOMAIN_GATHERING):
			domains.append(GameData.WORKER_DOMAIN_GATHERING)

	return domains

func _get_jobs_for_worker(worker: FarmWorker) -> Array:
	if worker == null:
		return jobs
	var domain_id: String = worker.get_worker_domain()
	var bucket: Array = _jobs_by_domain.get(domain_id, [])
	if not bucket.is_empty() or jobs.is_empty():
		return bucket

	# Safety net: if buckets drift out of sync, rebuild once before falling back.
	_rebuild_job_buckets()
	bucket = _jobs_by_domain.get(domain_id, [])
	if not bucket.is_empty():
		return bucket

	return jobs

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
		GameData.JOB_FETCH_ANIMAL:
			return 200
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

	return _pop_job_at(best_index)

func get_next_job_for_worker(worker: FarmWorker) -> Dictionary:
	if jobs.is_empty():
		return {}
	if worker == null:
		return get_next_job()

	var worker_jobs: Array = _get_jobs_for_worker(worker)
	if worker_jobs.is_empty():
		return {}

	var best_job: Dictionary = {}
	var best_priority: int = -1000000
	var best_distance: int = 1000000
	for job in worker_jobs:
		if not worker.matches_job(job):
			continue
		var priority: int = _get_job_priority(job)
		var distance: int = _get_job_distance_from_worker(worker, job)
		if best_job.is_empty() or priority > best_priority or (priority == best_priority and distance < best_distance):
			best_job = job
			best_priority = priority
			best_distance = distance

	if best_job.is_empty():
		return {}

	var best_index: int = _find_job_index(best_job)
	if best_index < 0:
		return {}

	return _pop_job_at(best_index)

func has_job_at(target_pos: Vector2i) -> bool:
	for job in jobs:
		if job.target_pos == target_pos:
			return true
	return false
