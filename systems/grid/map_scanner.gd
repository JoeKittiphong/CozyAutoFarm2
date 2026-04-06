class_name MapScanner
extends RefCounted

static func _merge_used_rect(base_rect: Rect2i, next_rect: Rect2i) -> Rect2i:
	if next_rect.size == Vector2i.ZERO:
		return base_rect
	if base_rect.size == Vector2i.ZERO:
		return next_rect
	return base_rect.merge(next_rect)

static func collect_used_rect(ground_layer: TileMapLayer, water_layer: TileMapLayer, obstacles_layer: TileMapLayer, resource_layer: TileMapLayer) -> Rect2i:
	var used_rect := Rect2i()
	if ground_layer != null:
		used_rect = _merge_used_rect(used_rect, ground_layer.get_used_rect())
	if water_layer != null:
		used_rect = _merge_used_rect(used_rect, water_layer.get_used_rect())
	if obstacles_layer != null:
		used_rect = _merge_used_rect(used_rect, obstacles_layer.get_used_rect())
	if resource_layer != null:
		used_rect = _merge_used_rect(used_rect, resource_layer.get_used_rect())
	return used_rect

static func collect_ground_cells(ground_layer: TileMapLayer) -> Array[Vector2i]:
	if ground_layer == null:
		return []
	return ground_layer.get_used_cells()

static func collect_water_cells(water_layer: TileMapLayer) -> Array[Vector2i]:
	if water_layer == null:
		return []
	return water_layer.get_used_cells()

static func collect_obstacle_cells(obstacles_layer: TileMapLayer) -> Array[Vector2i]:
	if obstacles_layer == null:
		return []
	return obstacles_layer.get_used_cells()

static func collect_resource_cells(resource_layer: TileMapLayer) -> Array[Vector2i]:
	if resource_layer == null:
		return []
	return resource_layer.get_used_cells()

static func apply_layers_to_grid(ground_layer: TileMapLayer, water_layer: TileMapLayer, obstacles_layer: TileMapLayer, resource_layer: TileMapLayer) -> void:
	var map_rect: Rect2i = collect_used_rect(ground_layer, water_layer, obstacles_layer, resource_layer)
	var ground_cells: Array[Vector2i] = collect_ground_cells(ground_layer)
	var water_cells: Array[Vector2i] = collect_water_cells(water_layer)
	var obstacle_cells: Array[Vector2i] = collect_obstacle_cells(obstacles_layer)
	var resource_cells: Array[Vector2i] = collect_resource_cells(resource_layer)
	GridManager.reset_map_cells(map_rect, ground_cells, water_cells, obstacle_cells, resource_cells)
