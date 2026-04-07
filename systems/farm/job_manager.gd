extends Node
class_name JobManagerClass

const AUTO_GATHER_INTERVAL := 3

var jobs: Array[Dictionary] = []
var _auto_non_resource_jobs_since_gather: int = 0

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

func get_next_job() -> Dictionary:
	var resource_index: int = _find_first_resource_job_index()
	if resource_index >= 0 and _auto_non_resource_jobs_since_gather >= AUTO_GATHER_INTERVAL:
		_auto_non_resource_jobs_since_gather = 0
		return _pop_job_at(resource_index)

	var index := _find_first_job_index(true)
	if index < 0:
		return {}

	var job_type: String = String(jobs[index].get("type", ""))
	if job_type == GameData.JOB_GATHER_RESOURCE:
		_auto_non_resource_jobs_since_gather = 0
	else:
		_auto_non_resource_jobs_since_gather += 1
	return _pop_job_at(index)

func get_next_job_for_worker(worker: FarmWorker) -> Dictionary:
	if jobs.is_empty():
		return {}
	if worker == null or worker.uses_auto_job_selection():
		return get_next_job()

	for index in range(jobs.size()):
		var job: Dictionary = jobs[index]
		if worker.matches_job(job):
			return _pop_job_at(index)

	if worker.can_help_when_idle():
		var fallback_index := _find_first_job_index(true)
		if fallback_index >= 0:
			return _pop_job_at(fallback_index)
	return {}

func has_job_at(target_pos: Vector2i) -> bool:
	for job in jobs:
		if job.target_pos == target_pos:
			return true
	return false
