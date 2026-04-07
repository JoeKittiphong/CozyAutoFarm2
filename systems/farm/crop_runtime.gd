extends RefCounted
class_name CropRuntime

var _farm_data: Dictionary
var _growth_time: Dictionary
var _job_manager: Node
var _visual_notifier: Callable
var _tile_states: Dictionary

func setup(farm_data: Dictionary, growth_time: Dictionary, job_manager: Node, visual_notifier: Callable, tile_states: Dictionary) -> CropRuntime:
	_farm_data = farm_data
	_growth_time = growth_time
	_job_manager = job_manager
	_visual_notifier = visual_notifier
	_tile_states = tile_states
	return self

func process_growth(cell: Vector2i, delta: float, crop_type: String, level: int) -> void:
	if not _growth_time.has(cell):
		return

	_growth_time[cell] -= delta
	if _growth_time[cell] > 0.0:
		return

	_farm_data[cell]["state"] = int(_tile_states.get("READY_TO_HARVEST", 0))
	_growth_time.erase(cell)
	_job_manager.add_job(GameData.JOB_HARVEST, cell, {"crop_type": crop_type, "item_type": crop_type})
	_visual_notifier.call(cell, "READY", GameData.get_crop_visual(crop_type, "ready", level))

func place_blueprint(cell: Vector2i, crop_type: String, blueprint_id: String) -> void:
	_farm_data[cell] = {
		"state": int(_tile_states.get("BLUEPRINT", 0)),
		"type": crop_type,
		"blueprint_id": blueprint_id,
		"level": 1,
	}
	_job_manager.add_job(GameData.JOB_TILL, cell, {"crop_type": crop_type, "item_type": crop_type})

func complete_till(cell: Vector2i, crop_type: String) -> void:
	_farm_data[cell]["state"] = int(_tile_states.get("TILLED", 0))
	_job_manager.add_job(GameData.JOB_PLANT, cell, {"crop_type": crop_type, "item_type": crop_type})
	_visual_notifier.call(cell, "TILLED", "res://assets/sprites/dirt.png")

func complete_plant(cell: Vector2i, crop_type: String, level: int) -> void:
	_farm_data[cell]["state"] = int(_tile_states.get("PLANTED", 0))
	_job_manager.add_job(GameData.JOB_WATER, cell, {"crop_type": crop_type, "item_type": crop_type})
	_visual_notifier.call(cell, "PLANTED", GameData.get_crop_visual(crop_type, "sprout", level))

func complete_water(cell: Vector2i, grow_time: float) -> void:
	_farm_data[cell]["state"] = int(_tile_states.get("GROWING", 0))
	_growth_time[cell] = grow_time

func complete_harvest(cell: Vector2i, crop_type: String) -> void:
	_farm_data[cell]["state"] = int(_tile_states.get("BLUEPRINT", 0))
	_job_manager.add_job(GameData.JOB_TILL, cell, {"crop_type": crop_type, "item_type": crop_type})
	_visual_notifier.call(cell, "HARVESTED", "res://assets/sprites/blueprint_indicator.png")
