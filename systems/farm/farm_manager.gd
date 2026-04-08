extends Node
class_name FarmManagerClass

const CropRuntimeClass = preload("res://systems/farm/crop_runtime.gd")
const ProcessorRuntimeClass = preload("res://systems/farm/processor_runtime.gd")
const BuildingRuntimeClass = preload("res://systems/farm/building_runtime.gd")
const UpgradeRuntimeClass = preload("res://systems/farm/upgrade_runtime.gd")

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
	BUILDING,
}

var _farm_data: Dictionary = {}
var _growth_time: Dictionary = {}
var _processor_data: Dictionary = {}
var _crop_runtime: CropRuntime
var _processor_runtime: ProcessorRuntime
var _building_runtime: BuildingRuntime
var _upgrade_runtime: UpgradeRuntime
var _animal_by_home_pos: Dictionary = {}
const TIME_TO_GROW := 30.0
const PROCESSOR_INPUT_RETRY_SECONDS := 5.0
const FARM_TICK_SECONDS := 0.25

var _active_growing_cells: Dictionary = {}
var _active_processor_cells: Dictionary = {}
var _farm_tick_accumulator: float = 0.0

@onready var _job_manager: Node = get_node("/root/JobManager")
@onready var _world: Node = get_node_or_null("/root/World")
@onready var _inventory_manager: Node = get_node("/root/InventoryManager")

func _ready() -> void:
	_crop_runtime = CropRuntimeClass.new().setup(
		_farm_data,
		_growth_time,
		_job_manager,
		Callable(self, "_notify_world_visual"),
		{
			"BLUEPRINT": TileState.BLUEPRINT,
			"TILLED": TileState.TILLED,
			"PLANTED": TileState.PLANTED,
			"GROWING": TileState.GROWING,
			"READY_TO_HARVEST": TileState.READY_TO_HARVEST,
		}
	)
	_processor_runtime = ProcessorRuntimeClass.new().setup(
		_processor_data,
		_job_manager,
		_inventory_manager,
		Callable(self, "_notify_world_visual"),
		Callable(self, "_get_safe_storage_pos"),
		Callable(self, "_get_processor_interaction_pos")
	)
	_building_runtime = BuildingRuntimeClass.new().setup(
		_farm_data,
		Callable(self, "_notify_world_visual"),
		{
			GameData.BLUEPRINT_COOP: TileState.COOP,
			GameData.BLUEPRINT_COW_PEN: TileState.COW_PEN,
		},
		TileState.BUILDING
	)
	_upgrade_runtime = UpgradeRuntimeClass.new().setup(
		_farm_data,
		_processor_data,
		_inventory_manager,
		Callable(self, "_notify_world_visual"),
		Callable(_building_runtime, "refresh_pen_visual"),
		Callable(self, "_refresh_pen_animals"),
		{
			"EMPTY": TileState.EMPTY,
			"PLANTED": TileState.PLANTED,
			"GROWING": TileState.GROWING,
			"READY_TO_HARVEST": TileState.READY_TO_HARVEST,
			"COOP": TileState.COOP,
			"COW_PEN": TileState.COW_PEN,
			"PROCESSOR": TileState.PROCESSOR,
		}
	)

func _process(delta: float) -> void:
	if _active_growing_cells.is_empty() and _active_processor_cells.is_empty():
		return

	_farm_tick_accumulator += delta
	if _farm_tick_accumulator < FARM_TICK_SECONDS:
		return

	var tick_delta: float = _farm_tick_accumulator
	_farm_tick_accumulator = 0.0
	_process_active_crops(tick_delta)
	_process_active_processors(tick_delta)

func _process_active_crops(delta: float) -> void:
	for cell in _active_growing_cells.keys():
		if get_tile_state(cell) != TileState.GROWING:
			_active_growing_cells.erase(cell)
			continue
		_crop_runtime.process_growth(cell, delta, get_tile_type(cell), get_tile_level(cell))
		if get_tile_state(cell) != TileState.GROWING:
			_active_growing_cells.erase(cell)

func _process_active_processors(delta: float) -> void:
	for cell in _active_processor_cells.keys():
		if not _processor_data.has(cell) or get_tile_state(cell) != TileState.PROCESSOR:
			_active_processor_cells.erase(cell)
			continue
		var processor_data: Dictionary = _processor_data.get(cell, {})
		if processor_data.get("state", "WAITING") == "PROCESSING":
			_processor_runtime.process_timer(cell, delta, get_tile_level(cell), _processor_runtime.get_primary_output(processor_data))
		else:
			_processor_runtime.process_tick(cell)

func place_blueprint(cell: Vector2i, crop_type: String = GameData.ITEM_WHEAT, blueprint_id: String = "") -> void:
	if get_tile_state(cell) != TileState.EMPTY:
		return
	if blueprint_id == "":
		blueprint_id = crop_type

	_crop_runtime.place_blueprint(cell, crop_type, blueprint_id)

func complete_till(cell: Vector2i) -> void:
	if not _farm_data.has(cell) or get_tile_state(cell) != TileState.BLUEPRINT:
		return

	_crop_runtime.complete_till(cell, get_tile_type(cell))

func complete_plant(cell: Vector2i) -> void:
	if not _farm_data.has(cell) or get_tile_state(cell) != TileState.TILLED:
		return

	_crop_runtime.complete_plant(cell, get_tile_type(cell), get_tile_level(cell))

func complete_water(cell: Vector2i) -> void:
	if not _farm_data.has(cell) or get_tile_state(cell) != TileState.PLANTED:
		return

	_crop_runtime.complete_water(cell, TIME_TO_GROW)
	_active_growing_cells[cell] = true

func complete_harvest(cell: Vector2i) -> void:
	if not _farm_data.has(cell) or get_tile_state(cell) != TileState.READY_TO_HARVEST:
		return

	_crop_runtime.complete_harvest(cell, get_tile_type(cell))
	_active_growing_cells.erase(cell)

func get_tile_state(cell: Vector2i) -> int:
	if not _farm_data.has(cell):
		return TileState.EMPTY
	return int(_farm_data[cell].get("state", TileState.EMPTY))

func get_tile_type(cell: Vector2i) -> String:
	if not _farm_data.has(cell):
		return ""
	return String(_farm_data[cell].get("type", ""))

func get_blueprint_id(cell: Vector2i) -> String:
	if not _farm_data.has(cell):
		return ""
	return String(_farm_data[cell].get("blueprint_id", get_tile_type(cell)))

func get_processor_type(cell: Vector2i) -> String:
	if not _processor_data.has(cell):
		return ""
	return String(_processor_data[cell].get("processor_type", ""))

func _notify_world_visual(cell: Vector2i, state_name: String, tex_path: String) -> void:
	if _world == null:
		_world = get_node_or_null("/root/World")
	if _world != null:
		_world.update_tile_visual(cell, state_name, tex_path)

func register_building(cell: Vector2i, tile_type: String, blueprint_id: String = "") -> void:
	if blueprint_id == "":
		blueprint_id = tile_type
	_building_runtime.register_building(cell, tile_type, blueprint_id)

func register_processor(cell: Vector2i, processor_type: String, blueprint_id: String = "") -> void:
	var processor_def: ProcessorDefinition = GameData.get_processor_def(processor_type)
	if processor_def == null:
		return
	if blueprint_id == "":
		blueprint_id = processor_type

	_farm_data[cell] = {
		"state": TileState.PROCESSOR,
		"type": processor_type,
		"blueprint_id": blueprint_id,
		"level": 1,
	}
	_processor_runtime.register_processor(cell, processor_type, processor_def)
	_active_processor_cells[cell] = true
	_notify_world_visual(cell, processor_type, GameData.get_processor_level_texture(processor_type, 1))

func cancel_processor_delivery(cell: Vector2i, item_type: String, retry_seconds: float = PROCESSOR_INPUT_RETRY_SECONDS) -> void:
	_processor_runtime.cancel_delivery(cell, item_type, retry_seconds)

func _get_safe_storage_pos(storage_pos: Vector2i) -> Vector2i:
	if GridManager.is_walkable_land_cell(storage_pos):
		return storage_pos
	return GridManager.find_nearest_walkable_land_cell(storage_pos, 12)

func _get_processor_interaction_pos(cell: Vector2i) -> Vector2i:
	if GridManager.is_walkable_land_cell(cell):
		return cell
	return GridManager.find_nearest_walkable_land_cell(cell, 8)

func deliver_to_processor(cell: Vector2i, item_type: String, amount: int = 1) -> void:
	_processor_runtime.deliver_to_processor(cell, item_type, amount)

func collect_from_processor(cell: Vector2i) -> Dictionary:
	return _processor_runtime.collect_from_processor(cell, get_tile_level(cell))

func get_tile_level(cell: Vector2i) -> int:
	return _upgrade_runtime.get_tile_level(cell)

func get_tile_upgrade_price(cell: Vector2i) -> int:
	return _upgrade_runtime.get_tile_upgrade_price(cell)

func upgrade_tile(cell: Vector2i) -> bool:
	return _upgrade_runtime.upgrade_tile(cell)

func _refresh_tile_visual(cell: Vector2i) -> void:
	_upgrade_runtime.refresh_tile_visual(cell)

func _refresh_pen_animals(cell: Vector2i, _pen_type: String, level: int) -> void:
	var animal := get_animal_at(cell)
	if animal is FarmAnimal:
		animal.update_visual(level)

func register_animal(cell: Vector2i, animal: Node2D) -> void:
	if cell == Vector2i(-999, -999) or animal == null:
		return
	_animal_by_home_pos[cell] = animal

func unregister_animal(cell: Vector2i, animal: Node2D = null) -> void:
	if not _animal_by_home_pos.has(cell):
		return
	if animal != null and _animal_by_home_pos.get(cell) != animal:
		return
	_animal_by_home_pos.erase(cell)

func get_animal_at(cell: Vector2i) -> Node2D:
	var animal: Node2D = _animal_by_home_pos.get(cell, null)
	if animal != null and is_instance_valid(animal):
		return animal
	if animal != null:
		_animal_by_home_pos.erase(cell)
	return null

func find_empty_pen(pen_type: String) -> Vector2i:
	for cell in _farm_data.keys():
		if get_tile_type(cell) != pen_type:
			continue
		if get_animal_at(cell) == null:
			return cell
	return Vector2i(-999, -999)
