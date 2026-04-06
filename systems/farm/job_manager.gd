extends Node
class_name JobManagerClass

var jobs: Array[Dictionary] = []

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

func get_next_job() -> Dictionary:
	if jobs.is_empty():
		return {}
	return jobs.pop_front()

func get_next_job_for_worker(worker: FarmWorker) -> Dictionary:
	if jobs.is_empty():
		return {}
	if worker == null or worker.uses_auto_job_selection():
		return jobs.pop_front()

	for index in range(jobs.size()):
		var job: Dictionary = jobs[index]
		if worker.matches_job(job):
			var selected_job: Dictionary = job
			jobs.remove_at(index)
			return selected_job

	if worker.can_help_when_idle():
		return jobs.pop_front()
	return {}

func has_job_at(target_pos: Vector2i) -> bool:
	for job in jobs:
		if job.target_pos == target_pos:
			return true
	return false
