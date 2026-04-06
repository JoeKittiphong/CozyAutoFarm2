extends Node
class_name FarmManagerClass

const GameData = preload("res://systems/core/game_data.gd")

enum TileState {
	EMPTY,
	BLUEPRINT,
	TILLED,
	PLANTED,
	WATERED,
	GROWING,
	READY_TO_HARVEST,
	COOP,
	COW_PEN,
	PROCESSOR,
}

var _farm_data: Dictionary = {}
var _growth_time: Dictionary = {}
var _processor_data: Dictionary = {}
const TIME_TO_GROW := 30.0

@onready var _job_manager: Node = get_node("/root/JobManager")
@onready var _world: Node = get_node_or_null("/root/World")
@onready var _inventory_manager: Node = get_node("/root/InventoryManager")

func _process(delta: float) -> void:
	for cell in _farm_data.keys():
		var state := get_tile_state(cell)
		if state == TileState.GROWING:
			_process_crop_growth(cell, delta)
		elif state == TileState.PROCESSOR:
			_process_processor(cell, delta)

func _process_crop_growth(cell: Vector2i, delta: float) -> void:
	if not _growth_time.has(cell):
		return

	_growth_time[cell] -= delta
	if _growth_time[cell] > 0.0:
		return

	_farm_data[cell]["state"] = TileState.READY_TO_HARVEST
	_growth_time.erase(cell)
	_job_manager.add_job(GameData.JOB_HARVEST, cell)
	_notify_world_visual(cell, "READY", GameData.get_crop_visual(get_tile_type(cell), "ready"))

func _process_processor(cell: Vector2i, delta: float) -> void:
	if not _processor_data.has(cell):
		return

	var data: Dictionary = _processor_data[cell]
	if data.get("state", "WAITING") == "PROCESSING":
		data["timer"] = float(data.get("timer", 0.0)) - delta
		if float(data.get("timer", 0.0)) <= 0.0:
			data["state"] = "READY"
			var output_def: Dictionary = _get_primary_output(data)
			_job_manager.add_job(GameData.JOB_PROCESSOR_COLLECT, cell, {
				"item_type": String(output_def.get("item", "")),
				"amount": int(output_def.get("amount", 1)),
				"storage_pos": data.get("collect_storage_pos", GameData.PROCESSING_STORAGE_POS),
			})
			_notify_world_visual(cell, String(data.get("ready_state_name", "READY")), String(data.get("ready_texture_path", "")))
	elif data.get("state", "WAITING") == "WAITING":
		_request_processor_ingredients(cell)

func place_blueprint(cell: Vector2i, crop_type: String = GameData.ITEM_WHEAT) -> void:
	if get_tile_state(cell) != TileState.EMPTY:
		return

	_farm_data[cell] = {
		"state": TileState.BLUEPRINT,
		"type": crop_type,
		"level": 1,
	}
	_job_manager.add_job(GameData.JOB_TILL, cell)

func complete_till(cell: Vector2i) -> void:
	if not _farm_data.has(cell) or get_tile_state(cell) != TileState.BLUEPRINT:
		return

	_farm_data[cell]["state"] = TileState.TILLED
	_job_manager.add_job(GameData.JOB_PLANT, cell)
	_notify_world_visual(cell, "TILLED", "res://assets/sprites/dirt.png")

func complete_plant(cell: Vector2i) -> void:
	if not _farm_data.has(cell) or get_tile_state(cell) != TileState.TILLED:
		return

	_farm_data[cell]["state"] = TileState.PLANTED
	_job_manager.add_job(GameData.JOB_WATER, cell)
	_notify_world_visual(cell, "PLANTED", GameData.get_crop_visual(get_tile_type(cell), "sprout"))

func complete_water(cell: Vector2i) -> void:
	if not _farm_data.has(cell) or get_tile_state(cell) != TileState.PLANTED:
		return

	_farm_data[cell]["state"] = TileState.GROWING
	_growth_time[cell] = TIME_TO_GROW

func complete_harvest(cell: Vector2i) -> void:
	if not _farm_data.has(cell) or get_tile_state(cell) != TileState.READY_TO_HARVEST:
		return

	_farm_data[cell]["state"] = TileState.BLUEPRINT
	_job_manager.add_job(GameData.JOB_TILL, cell)
	_notify_world_visual(cell, "HARVESTED", "res://assets/sprites/blueprint_indicator.png")

func get_tile_state(cell: Vector2i) -> int:
	if not _farm_data.has(cell):
		return TileState.EMPTY
	return int(_farm_data[cell].get("state", TileState.EMPTY))

func get_tile_type(cell: Vector2i) -> String:
	if not _farm_data.has(cell):
		return ""
	return String(_farm_data[cell].get("type", ""))

func get_processor_type(cell: Vector2i) -> String:
	if not _processor_data.has(cell):
		return ""
	return String(_processor_data[cell].get("processor_type", ""))

func _notify_world_visual(cell: Vector2i, state_name: String, tex_path: String) -> void:
	if _world == null:
		_world = get_node_or_null("/root/World")
	if _world != null:
		_world.update_tile_visual(cell, state_name, tex_path)

func register_building(cell: Vector2i, tile_type: String) -> void:
	var tile_state := TileState.COOP if tile_type == GameData.BLUEPRINT_COOP else TileState.COW_PEN
	_farm_data[cell] = {
		"state": tile_state,
		"type": tile_type,
		"level": 1,
	}

func register_processor(cell: Vector2i, processor_type: String) -> void:
	var processor_def := GameData.get_processor_def(processor_type)
	if processor_def == null:
		return

	_farm_data[cell] = {
		"state": TileState.PROCESSOR,
		"type": processor_type,
		"level": 1,
	}
	_processor_data[cell] = {
		"processor_type": processor_type,
		"state": "WAITING",
		"timer": 0.0,
		"level": 1,
		"jobs_requested": [],
		"stored_inputs": {},
		"deliver_storage_pos": processor_def.deliver_storage_pos,
		"collect_storage_pos": processor_def.collect_storage_pos,
		"ready_state_name": processor_def.ready_state_name,
		"ready_texture_path": processor_def.ready_texture_path,
	}

func _request_processor_ingredients(cell: Vector2i) -> void:
	var data: Dictionary = _processor_data.get(cell, {})
	var processor_def := GameData.get_processor_def(String(data.get("processor_type", "")))
	if processor_def == null:
		return
	var jobs_requested: Array = data.get("jobs_requested", [])
	var stored_inputs: Dictionary = data.get("stored_inputs", {})
	for input_def in processor_def.inputs:
		if input_def.item_def == null:
			continue
		var item_type: String = input_def.item_def.item_id
		var required: int = input_def.amount
		var stored := int(stored_inputs.get(item_type, 0))
		if stored >= required:
			continue
		if item_type in jobs_requested:
			continue

		_job_manager.add_job(GameData.JOB_PROCESSOR_DELIVER, cell, {
			"item_type": item_type,
			"amount": 1,
			"storage_pos": data.get("deliver_storage_pos", GameData.STORAGE_POS),
		})
		jobs_requested.append(item_type)

	data["jobs_requested"] = jobs_requested

func deliver_to_processor(cell: Vector2i, item_type: String, amount: int = 1) -> void:
	if not _processor_data.has(cell):
		return

	var data: Dictionary = _processor_data[cell]
	var processor_def := GameData.get_processor_def(String(data.get("processor_type", "")))
	if processor_def == null:
		return
	var stored_inputs: Dictionary = data.get("stored_inputs", {})
	stored_inputs[item_type] = int(stored_inputs.get(item_type, 0)) + amount
	data["stored_inputs"] = stored_inputs

	var jobs_requested: Array = data.get("jobs_requested", [])
	if item_type in jobs_requested:
		jobs_requested.erase(item_type)
	data["jobs_requested"] = jobs_requested

	if _has_all_processor_inputs(processor_def, stored_inputs):
		data["state"] = "PROCESSING"
		data["timer"] = processor_def.base_duration / pow(1.5, int(data.get("level", 1)) - 1)

func collect_from_processor(cell: Vector2i) -> Dictionary:
	if not _processor_data.has(cell):
		return {}

	var data: Dictionary = _processor_data[cell]
	if data.get("state", "WAITING") != "READY":
		return {}

	var processor_def := GameData.get_processor_def(String(data.get("processor_type", "")))
	if processor_def == null:
		return {}
	var result: Dictionary = {}
	if not processor_def.outputs.is_empty():
		var output_def = processor_def.outputs[0]
		if output_def.item_def != null:
			result = {"item": output_def.item_def.item_id, "amount": output_def.amount}

	data["stored_inputs"] = {}
	data["state"] = "WAITING"
	data["timer"] = 0.0
	data["jobs_requested"] = []
	return result

func _has_all_processor_inputs(processor_def, stored_inputs: Dictionary) -> bool:
	for input_def in processor_def.inputs:
		if input_def.item_def == null:
			return false
		var item_type: String = input_def.item_def.item_id
		if int(stored_inputs.get(item_type, 0)) < input_def.amount:
			return false
	return true

func _get_primary_output(data: Dictionary) -> Dictionary:
	var processor_def := GameData.get_processor_def(String(data.get("processor_type", "")))
	if processor_def != null and not processor_def.outputs.is_empty():
		var output_def = processor_def.outputs[0]
		if output_def.item_def != null:
			return {"item": output_def.item_def.item_id, "amount": output_def.amount}
	return {}

func get_tile_level(cell: Vector2i) -> int:
	if _farm_data.has(cell):
		return int(_farm_data[cell].get("level", 1))
	return 1

func get_tile_upgrade_price(cell: Vector2i) -> int:
	var lvl := get_tile_level(cell)
	var state := get_tile_state(cell)
	return GameData.get_tile_upgrade_price(state == TileState.PROCESSOR, lvl)

func upgrade_tile(cell: Vector2i) -> bool:
	if not _farm_data.has(cell):
		return false

	var data: Dictionary = _farm_data[cell]
	var lvl := int(data.get("level", 1))
	if lvl >= GameData.MAX_UPGRADE_LEVEL:
		return false

	var price := get_tile_upgrade_price(cell)
	if not _inventory_manager.spend_money(price):
		return false

	data["level"] = lvl + 1
	if _processor_data.has(cell):
		_processor_data[cell]["level"] = lvl + 1
	_inventory_manager.resources_updated.emit()
	return true
