extends RefCounted
class_name UpgradeRuntime

var _farm_data: Dictionary
var _processor_data: Dictionary
var _inventory_manager: Node
var _visual_notifier: Callable
var _pen_visual_refresher: Callable
var _pen_animals_refresher: Callable
var _tile_states: Dictionary

func setup(
		farm_data: Dictionary,
		processor_data: Dictionary,
		inventory_manager: Node,
		visual_notifier: Callable,
		pen_visual_refresher: Callable,
		pen_animals_refresher: Callable,
		tile_states: Dictionary
	) -> UpgradeRuntime:
	_farm_data = farm_data
	_processor_data = processor_data
	_inventory_manager = inventory_manager
	_visual_notifier = visual_notifier
	_pen_visual_refresher = pen_visual_refresher
	_pen_animals_refresher = pen_animals_refresher
	_tile_states = tile_states
	return self

func get_tile_level(cell: Vector2i) -> int:
	if _farm_data.has(cell):
		return int(_farm_data[cell].get("level", 1))
	return 1

func get_tile_upgrade_price(cell: Vector2i) -> int:
	var level := get_tile_level(cell)
	var state := get_tile_state(cell)
	return GameData.get_tile_upgrade_price(state == int(_tile_states.get("PROCESSOR", 0)), level)

func upgrade_tile(cell: Vector2i) -> bool:
	if not _farm_data.has(cell):
		return false

	var data: Dictionary = _farm_data[cell]
	var level := int(data.get("level", 1))
	if level >= GameData.MAX_UPGRADE_LEVEL:
		return false

	var price := get_tile_upgrade_price(cell)
	if _inventory_manager == null or not _inventory_manager.spend_money(price):
		return false

	data["level"] = level + 1
	if _processor_data.has(cell):
		_processor_data[cell]["level"] = level + 1
	refresh_tile_visual(cell)
	_inventory_manager.resources_updated.emit()
	return true

func refresh_tile_visual(cell: Vector2i) -> void:
	var state: int = get_tile_state(cell)
	var level: int = get_tile_level(cell)
	if state == int(_tile_states.get("PLANTED", -1)) or state == int(_tile_states.get("GROWING", -1)):
		_visual_notifier.call(cell, "PLANTED", GameData.get_crop_visual(get_tile_type(cell), "sprout", level))
	elif state == int(_tile_states.get("READY_TO_HARVEST", -1)):
		_visual_notifier.call(cell, "READY", GameData.get_crop_visual(get_tile_type(cell), "ready", level))
	elif state == int(_tile_states.get("COOP", -1)) or state == int(_tile_states.get("COW_PEN", -1)):
		_pen_visual_refresher.call(cell, get_tile_type(cell), get_blueprint_id(cell), level)
		_pen_animals_refresher.call(cell, get_tile_type(cell), level)
	elif state == int(_tile_states.get("PROCESSOR", -1)):
		var processor_type: String = get_processor_type(cell)
		var processor_state: String = String(_processor_data.get(cell, {}).get("state", "WAITING"))
		if processor_state == "READY":
			_visual_notifier.call(cell, processor_type, GameData.get_processor_ready_texture(processor_type, level))
		else:
			_visual_notifier.call(cell, processor_type, GameData.get_processor_level_texture(processor_type, level))

func get_tile_state(cell: Vector2i) -> int:
	if not _farm_data.has(cell):
		return int(_tile_states.get("EMPTY", 0))
	return int(_farm_data[cell].get("state", int(_tile_states.get("EMPTY", 0))))

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
