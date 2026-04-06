extends Node
class_name JobManagerClass

const GameData = preload("res://systems/core/game_data.gd")

var jobs: Array[Dictionary] = []

func add_job(type: String, target_pos: Vector2i, extra_data: Dictionary = {}) -> void:
    if type != GameData.JOB_FETCH_ANIMAL:
        for job in jobs:
            if job.target_pos == target_pos and job.type == type:
                return
            
    var job_dict = {
        "type": type,
        "target_pos": target_pos
    }
    job_dict.merge(extra_data)
    jobs.append(job_dict)

func get_next_job() -> Dictionary:
    if jobs.is_empty():
        return {}
    return jobs.pop_front()
    
func has_job_at(target_pos: Vector2i) -> bool:
    for job in jobs:
        if job.target_pos == target_pos:
            return true
    return false
