extends RefCounted
class_name ProcessorRuntime

var _processor_data: Dictionary
var _job_manager: Node
var _inventory_manager: Node
var _visual_notifier: Callable
var _safe_storage_pos_getter: Callable
var _interaction_pos_getter: Callable

func setup(
		processor_data: Dictionary,
		job_manager: Node,
		inventory_manager: Node,
		visual_notifier: Callable,
		safe_storage_pos_getter: Callable,
		interaction_pos_getter: Callable
	) -> ProcessorRuntime:
	_processor_data = processor_data
	_job_manager = job_manager
	_inventory_manager = inventory_manager
	_visual_notifier = visual_notifier
	_safe_storage_pos_getter = safe_storage_pos_getter
	_interaction_pos_getter = interaction_pos_getter
	return self

func process_tick(cell: Vector2i) -> void:
	if not _processor_data.has(cell):
		return

	var data: Dictionary = _processor_data[cell]
	if data.get("state", "WAITING") == "PROCESSING":
		return
	if data.get("state", "WAITING") == "WAITING":
		request_ingredients(cell)

func process_timer(cell: Vector2i, delta: float, level: int, primary_output: Dictionary) -> void:
	if not _processor_data.has(cell):
		return

	var data: Dictionary = _processor_data[cell]
	data["timer"] = float(data.get("timer", 0.0)) - delta
	if float(data.get("timer", 0.0)) > 0.0:
		return

	data["state"] = "READY"
	_job_manager.add_job(GameData.JOB_PROCESSOR_COLLECT, cell, {
		"item_type": String(primary_output.get("item", "")),
		"output_item_type": String(primary_output.get("item", "")),
		"amount": int(primary_output.get("amount", 1)),
		"storage_pos": get_collect_storage_pos(data),
		"interaction_pos": _interaction_pos_getter.call(cell),
	})
	_visual_notifier.call(
		cell,
		String(data.get("ready_state_name", "READY")),
		GameData.get_processor_ready_texture(String(data.get("processor_type", "")), level)
	)

func register_processor(cell: Vector2i, processor_type: String, processor_def: ProcessorDefinition) -> void:
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

func request_ingredients(cell: Vector2i) -> void:
	var data: Dictionary = _processor_data.get(cell, {})
	var processor_def: ProcessorDefinition = GameData.get_processor_def(String(data.get("processor_type", "")))
	if processor_def == null:
		return

	var jobs_requested: Array = data.get("jobs_requested", [])
	var stored_inputs: Dictionary = data.get("stored_inputs", {})
	var retry_until: Dictionary = data.get("input_retry_until", {})
	var now_seconds: float = Time.get_ticks_msec() / 1000.0
	var storage_pos: Vector2i = get_deliver_storage_pos(data)
	var interaction_pos: Vector2i = _interaction_pos_getter.call(cell)
	if not GridManager.is_walkable_land_cell(storage_pos):
		return
	if not GridManager.is_walkable_land_cell(interaction_pos):
		return
	if storage_pos != interaction_pos and GridManager.get_path_cells(storage_pos, interaction_pos).is_empty():
		return

	for input_def in processor_def.inputs:
		if input_def.item_def == null:
			continue
		var item_type: String = input_def.item_def.item_id
		var required: int = input_def.amount
		var stored: int = int(stored_inputs.get(item_type, 0))
		if stored >= required:
			continue
		if item_type in jobs_requested:
			continue
		if float(retry_until.get(item_type, 0.0)) > now_seconds:
			continue
		if _inventory_manager.get_item_stock(item_type) < 1:
			continue

		var primary_output: Dictionary = get_primary_output(data)
		_job_manager.add_job(GameData.JOB_PROCESSOR_DELIVER, cell, {
			"item_type": item_type,
			"output_item_type": String(primary_output.get("item", "")),
			"amount": 1,
			"storage_pos": storage_pos,
			"interaction_pos": interaction_pos,
		})
		jobs_requested.append(item_type)

	data["jobs_requested"] = jobs_requested
	data["input_retry_until"] = retry_until

func cancel_delivery(cell: Vector2i, item_type: String, retry_seconds: float) -> void:
	if not _processor_data.has(cell):
		return
	var data: Dictionary = _processor_data[cell]
	var jobs_requested: Array = data.get("jobs_requested", [])
	if item_type in jobs_requested:
		jobs_requested.erase(item_type)
	data["jobs_requested"] = jobs_requested
	var retry_until: Dictionary = data.get("input_retry_until", {})
	retry_until[item_type] = (Time.get_ticks_msec() / 1000.0) + retry_seconds
	data["input_retry_until"] = retry_until

func get_deliver_storage_pos(data: Dictionary) -> Vector2i:
	var configured_pos: Vector2i = Vector2i(data.get("deliver_storage_pos", GameData.get_processing_storage_pos()))
	if configured_pos == Vector2i.ZERO:
		configured_pos = GameData.get_processing_storage_pos()
	return _safe_storage_pos_getter.call(configured_pos)

func get_collect_storage_pos(data: Dictionary) -> Vector2i:
	var configured_pos: Vector2i = Vector2i(data.get("collect_storage_pos", GameData.get_processing_storage_pos()))
	if configured_pos == Vector2i.ZERO:
		configured_pos = GameData.get_processing_storage_pos()
	return _safe_storage_pos_getter.call(configured_pos)

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

	if has_all_inputs(processor_def, stored_inputs):
		data["state"] = "PROCESSING"
		data["timer"] = processor_def.base_duration / pow(1.5, int(data.get("level", 1)) - 1)

func collect_from_processor(cell: Vector2i, level: int) -> Dictionary:
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
	_visual_notifier.call(cell, String(data.get("processor_type", "")), GameData.get_processor_level_texture(String(data.get("processor_type", "")), level))
	return result

func has_all_inputs(processor_def: ProcessorDefinition, stored_inputs: Dictionary) -> bool:
	for input_def in processor_def.inputs:
		if input_def.item_def == null:
			return false
		var item_type: String = input_def.item_def.item_id
		if int(stored_inputs.get(item_type, 0)) < input_def.amount:
			return false
	return true

func get_primary_output(data: Dictionary) -> Dictionary:
	var processor_def := GameData.get_processor_def(String(data.get("processor_type", "")))
	if processor_def != null and not processor_def.outputs.is_empty():
		var output_def = processor_def.outputs[0]
		if output_def.item_def != null:
			return {"item": output_def.item_def.item_id, "amount": output_def.amount}
	return {}
