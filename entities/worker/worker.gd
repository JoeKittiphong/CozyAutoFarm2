extends Node2D
class_name FarmWorker

@export var move_speed: float = 300.0

const MAX_CARRY := 3
const DIRECTION_FRONT := "front"
const DIRECTION_BACK := "back"
const DIRECTION_LEFT := "left"
const DIRECTION_RIGHT := "right"
const DIRECTION_TEXTURE_PATHS := {
	DIRECTION_FRONT: "res://assets/sprites/worker_front.png",
	DIRECTION_BACK: "res://assets/sprites/worker_back.png",
	DIRECTION_LEFT: "res://assets/sprites/worker_left.png",
	DIRECTION_RIGHT: "res://assets/sprites/worker_right.png",
}
static var _next_worker_id: int = 1

var worker_id: int = 0
var work_mode: String = GameData.WORK_MODE_AUTO
var assigned_role: String = GameData.WORKER_ROLE_CROP_CARE
var assigned_target_id: String = ""
var allow_fallback_jobs: bool = true

var current_path: Array[Vector2i] = []
var current_job: Dictionary = {}
var is_working := false
var carried_items: Dictionary = {}
var carried_animal: Node2D = null
var _work_tween: Tween
var _worker_direction_textures: Dictionary = {}
var _current_direction: String = DIRECTION_FRONT

@onready var sprite: Sprite2D = Sprite2D.new()
@onready var _job_manager: Node = get_node("/root/JobManager")
@onready var _inventory_manager: Node = get_node("/root/InventoryManager")
@onready var _farm_manager: Node = get_node("/root/FarmManager")
@onready var _grid_manager: Node = get_node("/root/GridManager")
@onready var _resource_manager: Node = get_node("/root/ResourceManager")

func _ready() -> void:
	if worker_id == 0:
		worker_id = _next_worker_id
		_next_worker_id += 1
	name = "Worker_%d" % worker_id
	add_to_group("workers")

	_load_directional_textures()
	_apply_direction_texture(_current_direction)
	sprite.position = Vector2(GameData.TILE_SIZE / 2.0, GameData.TILE_SIZE / 2.0)
	add_child(sprite)

func _process(delta: float) -> void:
	if is_working:
		return

	if current_path.is_empty():
		if current_job.is_empty():
			var job = _job_manager.get_next_job_for_worker(self)
			if job.is_empty():
				if _get_total_carried_items() > 0:
					_start_delivery()
				return

			current_job = job
			var grid_pos = _get_current_grid_pos()
			if _is_complex_job(current_job):
				_start_work()
			else:
				current_path = _grid_manager.get_path_cells(grid_pos, current_job.target_pos)
				if current_path.is_empty():
					if grid_pos == current_job.target_pos:
						if current_job.type == GameData.JOB_DELIVER:
							_complete_delivery()
						else:
							_start_work()
					else:
						current_job.clear()
		else:
			if current_job.type == GameData.JOB_DELIVER:
				if current_path.is_empty():
					_complete_delivery()
			elif current_path.is_empty():
				_start_work()
	else:
		var target_grid_pos = current_path[0]
		var target_world_pos = Vector2(target_grid_pos) * GameData.TILE_SIZE
		var dir = (target_world_pos - position).normalized()
		_update_direction_from_vector(dir)
		var dist = position.distance_to(target_world_pos)
		var move_amount = move_speed * delta
		if move_amount >= dist:
			position = target_world_pos
			current_path.pop_front()
		else:
			position += dir * move_amount

func _load_directional_textures() -> void:
	_worker_direction_textures.clear()
	for direction in DIRECTION_TEXTURE_PATHS.keys():
		var tex = ResourceLoader.load(String(DIRECTION_TEXTURE_PATHS[direction]))
		if tex != null:
			_worker_direction_textures[direction] = tex

	if _worker_direction_textures.is_empty():
		var fallback = GradientTexture2D.new()
		fallback.width = 80
		fallback.height = 80
		fallback.fill_to = Vector2(1, 1)
		var grad = Gradient.new()
		grad.set_color(0, Color.GOLD)
		grad.set_color(1, Color.ORANGE)
		fallback.gradient = grad
		for direction in DIRECTION_TEXTURE_PATHS.keys():
			_worker_direction_textures[direction] = fallback

func _apply_direction_texture(direction: String) -> void:
	var tex = _worker_direction_textures.get(direction, _worker_direction_textures.get(DIRECTION_FRONT, null))
	if tex == null:
		return
	sprite.texture = tex
	var t_size = tex.get_size()
	if t_size.x > 0.0 and t_size.y > 0.0:
		sprite.scale = Vector2(GameData.TILE_SIZE / t_size.x, GameData.TILE_SIZE / t_size.y) * 0.9
	_current_direction = direction

func _update_direction_from_vector(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var next_direction: String = _current_direction
	if abs(dir.x) > abs(dir.y):
		next_direction = DIRECTION_RIGHT if dir.x > 0.0 else DIRECTION_LEFT
	else:
		next_direction = DIRECTION_FRONT if dir.y > 0.0 else DIRECTION_BACK
	if next_direction != _current_direction:
		_apply_direction_texture(next_direction)

func uses_auto_job_selection() -> bool:
	return work_mode != GameData.WORK_MODE_ASSIGNED

func can_help_when_idle() -> bool:
	return work_mode == GameData.WORK_MODE_ASSIGNED and allow_fallback_jobs

func set_assignment(mode: String, role: String, target_id: String, allow_fallback: bool) -> void:
	work_mode = mode
	assigned_role = role
	assigned_target_id = target_id
	allow_fallback_jobs = allow_fallback

func get_assignment_data() -> Dictionary:
	return {
		"mode": work_mode,
		"role": assigned_role,
		"target_id": assigned_target_id,
		"allow_fallback": allow_fallback_jobs,
	}

func get_display_name() -> String:
	return "Worker #%d" % worker_id

func get_assignment_summary() -> String:
	if uses_auto_job_selection():
		return "Auto"
	var role_label: String = GameData.get_worker_role_label(assigned_role)
	var target_label: String = GameData.get_worker_target_label(assigned_role, assigned_target_id)
	var fallback_label := "Help" if allow_fallback_jobs else "Strict"
	return "%s / %s / %s" % [role_label, target_label, fallback_label]

func get_current_status() -> String:
	if not current_job.is_empty():
		return String(current_job.get("type", "Working"))
	if _get_total_carried_items() > 0:
		return "Delivering"
	return "Idle"

func matches_job(job: Dictionary) -> bool:
	if uses_auto_job_selection():
		return true

	var job_type: String = String(job.get("type", ""))
	match assigned_role:
		GameData.WORKER_ROLE_CROP_CARE:
			if job_type not in [GameData.JOB_TILL, GameData.JOB_PLANT, GameData.JOB_WATER, GameData.JOB_HARVEST]:
				return false
			if assigned_target_id == "":
				return true
			var job_crop_type: String = String(job.get("item_type", job.get("crop_type", _farm_manager.get_tile_type(job.target_pos))))
			return job_crop_type == assigned_target_id
		GameData.WORKER_ROLE_PROCESSOR_DELIVERY:
			if job_type != GameData.JOB_PROCESSOR_DELIVER:
				return false
			if assigned_target_id == "":
				return true
			return _farm_manager.get_processor_type(job.target_pos) == assigned_target_id
		GameData.WORKER_ROLE_PROCESSOR_COLLECT:
			if job_type != GameData.JOB_PROCESSOR_COLLECT:
				return false
			if assigned_target_id == "":
				return true
			return _farm_manager.get_processor_type(job.target_pos) == assigned_target_id
		GameData.WORKER_ROLE_ANIMAL_CARE:
			if job_type not in [GameData.JOB_FEED_ANIMAL, GameData.JOB_COLLECT_ANIMAL_PRODUCT, GameData.JOB_FETCH_ANIMAL]:
				return false
			if assigned_target_id == "":
				return true
			var animal_def: AnimalDefinition = GameData.get_animal_def(assigned_target_id)
			if animal_def == null:
				return false
			return String(job.get("group_name", animal_def.group_name)) == animal_def.group_name or String(job.get("animal_type", assigned_target_id)) == assigned_target_id
		GameData.WORKER_ROLE_RESOURCE_GATHERING:
			if job_type != GameData.JOB_GATHER_RESOURCE:
				return false
			if assigned_target_id == "":
				return true
			return String(job.get("resource_type", "")) == assigned_target_id
		GameData.WORKER_ROLE_GENERAL_DELIVERY:
			return job_type == GameData.JOB_DELIVER
		_:
			return true

func _is_complex_job(job: Dictionary) -> bool:
	var job_type: String = String(job.get("type", ""))
	return job_type in [
		GameData.JOB_FEED_ANIMAL,
		GameData.JOB_COLLECT_ANIMAL_PRODUCT,
		GameData.JOB_FETCH_ANIMAL,
		GameData.JOB_PROCESSOR_DELIVER,
		GameData.JOB_PROCESSOR_COLLECT,
		GameData.JOB_GATHER_RESOURCE,
	]

func _get_current_grid_pos() -> Vector2i:
	return Vector2i(round(position.x / GameData.TILE_SIZE), round(position.y / GameData.TILE_SIZE))

func _start_work() -> void:
	is_working = true
	if _work_tween and _work_tween.is_valid():
		_work_tween.kill()

	_work_tween = create_tween().set_loops(3)
	_work_tween.tween_property(sprite, "position:y", GameData.TILE_SIZE / 2.0 - 20, 0.15)
	_work_tween.tween_property(sprite, "position:y", GameData.TILE_SIZE / 2.0, 0.15)
	await get_tree().create_timer(1.0).timeout

	match String(current_job.get("type", "")):
		GameData.JOB_TILL:
			_farm_manager.complete_till(current_job.target_pos)
		GameData.JOB_PLANT:
			_farm_manager.complete_plant(current_job.target_pos)
		GameData.JOB_WATER:
			_farm_manager.complete_water(current_job.target_pos)
		GameData.JOB_HARVEST:
			_handle_harvest()
			return
		GameData.JOB_FEED_ANIMAL:
			_handle_feed_animal(
				String(current_job.get("item_type", "")),
				int(current_job.get("amount", 1)),
				String(current_job.get("group_name", ""))
			)
			return
		GameData.JOB_COLLECT_ANIMAL_PRODUCT:
			_handle_collect_animal_product(
				String(current_job.get("item_type", "")),
				String(current_job.get("group_name", "")),
				String(current_job.get("collect_method", ""))
			)
			return
		GameData.JOB_FETCH_ANIMAL:
			_handle_fetch_animal()
			return
		GameData.JOB_PROCESSOR_DELIVER:
			_handle_processor_deliver()
			return
		GameData.JOB_PROCESSOR_COLLECT:
			_handle_processor_collect()
			return
		GameData.JOB_GATHER_RESOURCE:
			_handle_gather_resource()
			return

	current_job.clear()
	is_working = false

func _handle_harvest() -> void:
	var crop_type: String = _farm_manager.get_tile_type(current_job.target_pos)
	var yield_amt: int = _farm_manager.get_tile_level(current_job.target_pos)
	_farm_manager.complete_harvest(current_job.target_pos)
	_add_carried_item(crop_type, yield_amt)
	current_job.clear()
	is_working = false
	if _get_total_carried_items() >= MAX_CARRY:
		_start_delivery()

func _handle_feed_animal(item_type: String, amount: int, group_name: String) -> void:
	if _get_carried_amount(item_type) < amount:
		var grid_pos = _get_current_grid_pos()
		var storage_pos = _get_storage_pos_for_item(item_type)
		if grid_pos != storage_pos:
			current_path = _grid_manager.get_path_cells(grid_pos, storage_pos)
			is_working = false
			return

		if item_type == GameData.ITEM_ANIMAL_FEED:
			if not _inventory_manager.consume_animal_feed_points(int(current_job.get("feed_points", 1))):
				if _try_swap_to_fallback_feed(item_type):
					is_working = false
					return
				_requeue_feed_job(item_type, amount, group_name)
				current_job.clear()
				is_working = false
				return
		else:
			if not _inventory_manager.spend_item(item_type, amount):
				if _try_swap_to_fallback_feed(item_type):
					is_working = false
					return
				_requeue_feed_job(item_type, amount, group_name)
				current_job.clear()
				is_working = false
				return

		_add_carried_item(item_type, amount)
		current_path = _grid_manager.get_path_cells(grid_pos, current_job.target_pos)
		is_working = false
		return

	for animal in get_tree().get_nodes_in_group(group_name):
		if animal.home_pos == current_job.target_pos:
			animal.feed()
			_remove_carried_item(item_type, amount)
			break

	current_job.clear()
	is_working = false

func _try_swap_to_fallback_feed(item_type: String) -> bool:
	var fallback_item_type: String = String(current_job.get("fallback_item_type", ""))
	var fallback_amount: int = int(current_job.get("fallback_amount", 1))
	if item_type != GameData.ITEM_ANIMAL_FEED:
		return false
	if fallback_item_type == "" or fallback_item_type == item_type:
		return false
	current_job["item_type"] = fallback_item_type
	current_job["amount"] = fallback_amount
	current_path.clear()
	return true

func _requeue_feed_job(item_type: String, amount: int, group_name: String) -> void:
	_job_manager.add_job(GameData.JOB_FEED_ANIMAL, current_job.target_pos, {
		"item_type": item_type,
		"amount": amount,
		"group_name": group_name,
		"fallback_item_type": String(current_job.get("fallback_item_type", "")),
		"fallback_amount": int(current_job.get("fallback_amount", amount)),
	})

func _handle_collect_animal_product(item_type: String, group_name: String, collect_method: String) -> void:
	if _get_carried_amount(item_type) < 1:
		var grid_pos = _get_current_grid_pos()
		if grid_pos != current_job.target_pos:
			current_path = _grid_manager.get_path_cells(grid_pos, current_job.target_pos)
			is_working = false
			return

		for animal in get_tree().get_nodes_in_group(group_name):
			if animal.home_pos == current_job.target_pos:
				animal.call(collect_method)
				_add_carried_item(item_type, 1)
				break

		current_path = _grid_manager.get_path_cells(grid_pos, GameData.STORAGE_POS)
		is_working = false
		return

	_inventory_manager.add_item(item_type, 1)
	_remove_carried_item(item_type, 1)
	current_job.clear()
	is_working = false

func _handle_fetch_animal() -> void:
	if carried_animal == null:
		var grid_pos = _get_current_grid_pos()
		if grid_pos != GameData.SHOP_POS:
			current_path = _grid_manager.get_path_cells(grid_pos, GameData.SHOP_POS)
			is_working = false
			return

		carried_animal = current_job.animal_node
		carried_animal.visible = false
		_update_carried_visual()

		var animal_type: String = String(current_job.get("animal_type", ""))
		var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
		if animal_def == null:
			carried_animal.visible = true
			carried_animal = null
			current_job.clear()
			is_working = false
			return
		var pen_type: String = animal_def.pen_blueprint_type
		var dest := Vector2i.ZERO
		var found := false
		for cell in _farm_manager._farm_data.keys():
			if _farm_manager.get_tile_type(cell) != pen_type:
				continue
			var has_an := false
			for animal in get_tree().get_nodes_in_group(animal_def.group_name):
				if animal.home_pos == cell:
					has_an = true
					break
			if not has_an:
				dest = cell
				found = true
				break

		if found:
			current_job.target_pos = dest
			current_path = _grid_manager.get_path_cells(grid_pos, dest)
		else:
			carried_animal.visible = true
			carried_animal = null
			current_job.clear()
		is_working = false
		return

	carried_animal.visible = true
	carried_animal.setup(current_job.target_pos)
	carried_animal = null
	_update_carried_visual()
	current_job.clear()
	is_working = false

func _handle_processor_deliver() -> void:
	var item_type: String = String(current_job.get("item_type", ""))
	var amount: int = int(current_job.get("amount", 1))
	var storage_pos: Vector2i = Vector2i(current_job.get("storage_pos", _get_storage_pos_for_item(item_type)))
	var interaction_pos: Vector2i = Vector2i(current_job.get("interaction_pos", current_job.target_pos))
	var grid_pos: Vector2i = _get_current_grid_pos()
	if _get_carried_amount(item_type) < amount:
		if grid_pos != storage_pos:
			current_path = _grid_manager.get_path_cells(grid_pos, storage_pos)
			if current_path.is_empty():
				if _farm_manager.has_method("cancel_processor_delivery"):
					_farm_manager.cancel_processor_delivery(current_job.target_pos, item_type)
				current_job.clear()
				is_working = false
				return
			is_working = false
			return

		if not _inventory_manager.spend_item(item_type, amount):
			if _farm_manager.has_method("cancel_processor_delivery"):
				_farm_manager.cancel_processor_delivery(current_job.target_pos, item_type)
			current_job.clear()
			is_working = false
			return

		_add_carried_item(item_type, amount)
		if grid_pos != interaction_pos:
			current_path = _grid_manager.get_path_cells(grid_pos, interaction_pos)
		else:
			current_path.clear()
		if current_path.is_empty() and grid_pos != interaction_pos:
			_remove_carried_item(item_type, amount)
			_inventory_manager.add_item(item_type, amount)
			if _farm_manager.has_method("cancel_processor_delivery"):
				_farm_manager.cancel_processor_delivery(current_job.target_pos, item_type)
			current_job.clear()
			is_working = false
			return
		is_working = false
		return

	if grid_pos != interaction_pos:
		current_path = _grid_manager.get_path_cells(grid_pos, interaction_pos)
		if current_path.is_empty():
			_remove_carried_item(item_type, amount)
			_inventory_manager.add_item(item_type, amount)
			if _farm_manager.has_method("cancel_processor_delivery"):
				_farm_manager.cancel_processor_delivery(current_job.target_pos, item_type)
			current_job.clear()
			is_working = false
			return
		is_working = false
		return

	_farm_manager.deliver_to_processor(current_job.target_pos, item_type, amount)
	_remove_carried_item(item_type, amount)
	current_job.clear()
	is_working = false

func _handle_processor_collect() -> void:
	var item_type: String = String(current_job.get("item_type", ""))
	var amount: int = int(current_job.get("amount", 1))
	var storage_pos: Vector2i = Vector2i(current_job.get("storage_pos", _get_storage_pos_for_item(item_type)))
	var interaction_pos: Vector2i = Vector2i(current_job.get("interaction_pos", current_job.target_pos))
	if _get_carried_amount(item_type) < amount:
		var grid_pos: Vector2i = _get_current_grid_pos()
		if grid_pos != interaction_pos:
			current_path = _grid_manager.get_path_cells(grid_pos, interaction_pos)
			if current_path.is_empty():
				current_job.clear()
				is_working = false
				return
			is_working = false
			return

		var collected: Dictionary = _farm_manager.collect_from_processor(current_job.target_pos)
		if collected.is_empty():
			current_job.clear()
			is_working = false
			return

		_add_carried_item(String(collected.get("item", item_type)), int(collected.get("amount", amount)))
		if grid_pos != storage_pos:
			current_path = _grid_manager.get_path_cells(grid_pos, storage_pos)
			if current_path.is_empty():
				_inventory_manager.add_item(String(collected.get("item", item_type)), int(collected.get("amount", amount)))
				_remove_carried_item(String(collected.get("item", item_type)), int(collected.get("amount", amount)))
				current_job.clear()
				is_working = false
				return
		else:
			current_path.clear()
		is_working = false
		return

	_inventory_manager.add_item(item_type, amount)
	_remove_carried_item(item_type, amount)
	current_job.clear()
	is_working = false

func _handle_gather_resource() -> void:
	var interaction_pos := Vector2i(current_job.get("interaction_pos", current_job.get("target_pos", Vector2i.ZERO)))
	var grid_pos = _get_current_grid_pos()
	if grid_pos != interaction_pos:
		current_path = _grid_manager.get_path_cells(grid_pos, interaction_pos)
		if current_path.is_empty():
			current_job.clear()
			is_working = false
			return
		is_working = false
		return

	var gathered: Dictionary = _resource_manager.gather_resource(Vector2i(current_job.get("target_pos", Vector2i.ZERO)))
	if gathered.is_empty():
		current_job.clear()
		is_working = false
		return

	_add_carried_item(String(gathered.get("item_type", "")), int(gathered.get("amount", 1)))
	current_job.clear()
	is_working = false
	if _get_total_carried_items() >= MAX_CARRY:
		_start_delivery()

func _get_storage_pos_for_item(item_type: String) -> Vector2i:
	return GameData.PROCESSING_STORAGE_POS if item_type in [GameData.ITEM_FLOUR, GameData.ITEM_TOMATO, GameData.ITEM_TOMATO_SAUCE] else GameData.STORAGE_POS

func _add_carried_item(item_type: String, amount: int) -> void:
	carried_items[item_type] = _get_carried_amount(item_type) + amount
	_update_carried_visual()

func _remove_carried_item(item_type: String, amount: int) -> void:
	var next_amount := _get_carried_amount(item_type) - amount
	if next_amount <= 0:
		carried_items.erase(item_type)
	else:
		carried_items[item_type] = next_amount
	_update_carried_visual()

func _get_carried_amount(item_type: String) -> int:
	return int(carried_items.get(item_type, 0))

func _get_total_carried_items() -> int:
	var total := 0
	for item_type in carried_items.keys():
		total += int(carried_items[item_type])
	return total

func _get_primary_carried_item() -> String:
	for item_type in GameData.get_item_order():
		if _get_carried_amount(item_type) > 0:
			return item_type
	return ""

func _update_carried_visual() -> void:
	if has_node("CarriedItem"):
		get_node("CarriedItem").queue_free()

	var tex_path := ""
	var count := 0
	var carried_item := _get_primary_carried_item()
	if carried_item != "":
		var item_def: ItemDefinition = GameData.get_item_def(carried_item)
		tex_path = item_def.icon_path if item_def != null else ""
		count = _get_carried_amount(carried_item)
	elif carried_animal != null:
		var animal_type: String = String(current_job.get("animal_type", GameData.ANIMAL_CHICKEN))
		var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
		tex_path = animal_def.icon_path if animal_def != null else ""
		count = 1

	if tex_path == "":
		return

	var item_sprite = Sprite2D.new()
	var tex = ResourceLoader.load(tex_path)
	if tex:
		item_sprite.texture = tex
		var t_size = tex.get_size()
		item_sprite.scale = Vector2(GameData.TILE_SIZE / t_size.x, GameData.TILE_SIZE / t_size.y) * 0.5
	item_sprite.name = "CarriedItem"
	add_child(item_sprite)
	item_sprite.position = Vector2(GameData.TILE_SIZE / 2.0, -10.0 - (count * 8))

func _start_delivery() -> void:
	current_job = {"type": GameData.JOB_DELIVER, "target_pos": GameData.PROCESSING_STORAGE_POS}
	current_path = _grid_manager.get_path_cells(_get_current_grid_pos(), current_job.target_pos)
	is_working = false

func _complete_delivery() -> void:
	is_working = true
	await get_tree().create_timer(0.5).timeout
	if has_node("CarriedItem"):
		get_node("CarriedItem").queue_free()

	for item_type in carried_items.keys():
		_inventory_manager.add_item(String(item_type), int(carried_items[item_type]))

	carried_items.clear()
	current_job.clear()
	is_working = false

