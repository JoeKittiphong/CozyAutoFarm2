extends Node
class_name ResourceManagerClass

var _resources: Dictionary = {}
var _resource_layer: TileMapLayer
var _world: Node
@onready var _job_manager: Node = get_node("/root/JobManager")

func register_from_layer(resource_layer: TileMapLayer) -> void:
	_resource_layer = resource_layer
	_resources.clear()
	if resource_layer == null:
		return

	for cell in resource_layer.get_used_cells():
		_register_resource_cell(resource_layer, cell)

func _register_resource_cell(resource_layer: TileMapLayer, cell: Vector2i) -> void:
	var resource_def: WorldResourceDefinition = _resolve_resource_def(resource_layer, cell)
	if resource_def == null:
		return

	var interaction_pos: Vector2i = GridManager.find_nearest_walkable_land_cell(cell, 8)
	if not GridManager.is_walkable_land_cell(interaction_pos):
		return

	_resources[cell] = {
		"resource_id": resource_def.resource_id,
		"interaction_pos": interaction_pos,
	}
	if _job_manager != null:
		_job_manager.add_job(GameData.JOB_GATHER_RESOURCE, cell, {
			"resource_type": resource_def.resource_id,
			"interaction_pos": interaction_pos,
		})

func _resolve_resource_def(resource_layer: TileMapLayer, cell: Vector2i) -> WorldResourceDefinition:
	var tile_data: TileData = resource_layer.get_cell_tile_data(cell)
	if tile_data != null:
		var custom_resource_id = tile_data.get_custom_data("resource_id")
		if custom_resource_id != null and String(custom_resource_id) != "":
			var custom_def: WorldResourceDefinition = GameData.get_world_resource_def(String(custom_resource_id))
			if custom_def != null:
				return custom_def

	var source_id: int = resource_layer.get_cell_source_id(cell)
	var atlas_coords: Vector2i = resource_layer.get_cell_atlas_coords(cell)
	return GameData.get_world_resource_def_by_tile(source_id, atlas_coords)

func has_resource_at(cell: Vector2i) -> bool:
	return _resources.has(cell)

func get_resource_type(cell: Vector2i) -> String:
	return String(_resources.get(cell, {}).get("resource_id", ""))

func get_interaction_pos(cell: Vector2i) -> Vector2i:
	return Vector2i(_resources.get(cell, {}).get("interaction_pos", cell))

func gather_resource(cell: Vector2i) -> Dictionary:
	if not _resources.has(cell):
		return {}
	var resource_type: String = get_resource_type(cell)
	var resource_def: WorldResourceDefinition = GameData.get_world_resource_def(resource_type)
	if resource_def == null or resource_def.drop_item_def == null:
		return {}

	_resources.erase(cell)
	if _resource_layer != null:
		_resource_layer.erase_cell(cell)
	GridManager.clear_resource_blocker(cell)

	if _world == null:
		_world = get_node_or_null("/root/World")
	if _world != null and _world.has_method("clear_resource_tile"):
		_world.clear_resource_tile(cell)

	if _resource_layer != null:
		register_from_layer(_resource_layer)

	return {
		"item_type": resource_def.drop_item_def.item_id,
		"amount": resource_def.drop_amount,
	}
