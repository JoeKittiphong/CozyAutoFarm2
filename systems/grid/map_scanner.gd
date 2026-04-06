class_name MapScanner
extends RefCounted

static func collect_walkable_cells(ground_layer: TileMapLayer) -> Array[Vector2i]:
	if ground_layer == null:
		return []
	return ground_layer.get_used_cells()

static func collect_blocked_cells(obstacles_layer: TileMapLayer) -> Array[Vector2i]:
	if obstacles_layer == null:
		return []
	return obstacles_layer.get_used_cells()

static func apply_layers_to_grid(ground_layer: TileMapLayer, obstacles_layer: TileMapLayer) -> void:
	var walkable_cells: Array[Vector2i] = collect_walkable_cells(ground_layer)
	var blocked_cells: Array[Vector2i] = collect_blocked_cells(obstacles_layer)
	GridManager.reset_map_cells(walkable_cells, blocked_cells)
