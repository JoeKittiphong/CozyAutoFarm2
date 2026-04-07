extends RefCounted
class_name BuildingRuntime

var _farm_data: Dictionary
var _visual_notifier: Callable
var _building_state_map: Dictionary
var _default_building_state: int

func setup(farm_data: Dictionary, visual_notifier: Callable, building_state_map: Dictionary, default_building_state: int = 0) -> BuildingRuntime:
	_farm_data = farm_data
	_visual_notifier = visual_notifier
	_building_state_map = building_state_map
	_default_building_state = default_building_state
	return self

func register_building(cell: Vector2i, tile_type: String, blueprint_id: String) -> void:
	var tile_state: int = int(_building_state_map.get(tile_type, _building_state_map.get(blueprint_id, _default_building_state)))
	_farm_data[cell] = {
		"state": tile_state,
		"type": tile_type,
		"blueprint_id": blueprint_id,
		"level": 1,
	}
	_visual_notifier.call(cell, tile_type, GameData.get_blueprint_level_texture(blueprint_id, 1))

func refresh_pen_visual(cell: Vector2i, tile_type: String, blueprint_id: String, level: int) -> void:
	_visual_notifier.call(cell, tile_type, GameData.get_blueprint_level_texture(blueprint_id, level))
