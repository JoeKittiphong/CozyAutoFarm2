extends Node
class_name GridManagerClass


const DEFAULT_GRID_REGION := Rect2i(-50, -50, 100, 100)
const MAX_REACHABILITY_PATH_CHECKS := 8

var grid: AStarGrid2D
var ground_cells: Dictionary = {}
var water_cells: Dictionary = {}
var obstacle_blocked_cells: Dictionary = {}
var resource_blocked_cells: Dictionary = {}

func _ready() -> void:
	grid = AStarGrid2D.new()
	_configure_grid(DEFAULT_GRID_REGION)

func _configure_grid(region: Rect2i) -> void:
	grid.region = region
	grid.cell_size = Vector2(GameData.TILE_SIZE, GameData.TILE_SIZE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()

func get_path_cells(start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]:
	if not grid.is_in_bounds(start_cell.x, start_cell.y) or not grid.is_in_bounds(end_cell.x, end_cell.y):
		return []
	return grid.get_id_path(start_cell, end_cell)

func set_cell_solid(cell: Vector2i, solid: bool) -> void:
	if grid.is_in_bounds(cell.x, cell.y):
		grid.set_point_solid(cell, solid)

func _refresh_cell_solid(cell: Vector2i) -> void:
	set_cell_solid(cell, is_water_cell(cell) or has_obstacle_blocker(cell) or has_resource_blocker(cell))

func is_cell_solid(cell: Vector2i) -> bool:
	if grid == null:
		return true
	if not grid.is_in_bounds(cell.x, cell.y):
		return true
	return grid.is_point_solid(cell)

func is_ground_cell(cell: Vector2i) -> bool:
	return ground_cells.has(cell)

func is_water_cell(cell: Vector2i) -> bool:
	return water_cells.has(cell)

func has_obstacle_blocker(cell: Vector2i) -> bool:
	return obstacle_blocked_cells.has(cell)

func has_resource_blocker(cell: Vector2i) -> bool:
	return resource_blocked_cells.has(cell)

func is_blocked_cell(cell: Vector2i) -> bool:
	return has_obstacle_blocker(cell) or has_resource_blocker(cell)

func clear_resource_blocker(cell: Vector2i) -> void:
	resource_blocked_cells.erase(cell)
	_refresh_cell_solid(cell)

func clear_all_blockers(cell: Vector2i) -> void:
	obstacle_blocked_cells.erase(cell)
	resource_blocked_cells.erase(cell)
	_refresh_cell_solid(cell)

func is_buildable_on_land(cell: Vector2i) -> bool:
	return is_ground_cell(cell) and not is_water_cell(cell) and not is_blocked_cell(cell)

func is_buildable_on_water(cell: Vector2i) -> bool:
	return is_water_cell(cell) and not is_blocked_cell(cell)

func is_walkable_land_cell(cell: Vector2i) -> bool:
	return is_ground_cell(cell) and not is_water_cell(cell) and not is_cell_solid(cell)

func find_nearest_walkable_land_cell(origin: Vector2i, max_radius: int = 8) -> Vector2i:
	if is_walkable_land_cell(origin):
		return origin

	for radius in range(1, max_radius + 1):
		for x in range(origin.x - radius, origin.x + radius + 1):
			for y in range(origin.y - radius, origin.y + radius + 1):
				var candidate := Vector2i(x, y)
				if abs(candidate.x - origin.x) != radius and abs(candidate.y - origin.y) != radius:
					continue
				if is_walkable_land_cell(candidate):
					return candidate

	return origin

func find_nearest_cardinal_walkable_land_cell(origin: Vector2i, max_radius: int = 8) -> Vector2i:
	if is_walkable_land_cell(origin):
		return origin

	for radius in range(1, max_radius + 1):
		var candidates: Array[Vector2i] = [
			Vector2i(origin.x, origin.y - radius),
			Vector2i(origin.x + radius, origin.y),
			Vector2i(origin.x, origin.y + radius),
			Vector2i(origin.x - radius, origin.y),
		]
		for candidate in candidates:
			if is_walkable_land_cell(candidate):
				return candidate

	return origin

func find_reachable_land_cell_near(origin: Vector2i, from_cell: Vector2i, max_radius: int = 8, cardinal_only: bool = false) -> Vector2i:
	if is_walkable_land_cell(origin):
		var direct_path: Array[Vector2i] = get_path_cells(from_cell, origin)
		if not direct_path.is_empty() or from_cell == origin:
			return origin

	var path_checks: int = 0
	for radius in range(1, max_radius + 1):
		var candidates: Array[Vector2i] = []
		if cardinal_only:
			candidates = [
				Vector2i(origin.x, origin.y - radius),
				Vector2i(origin.x + radius, origin.y),
				Vector2i(origin.x, origin.y + radius),
				Vector2i(origin.x - radius, origin.y),
			]
		else:
			for x in range(origin.x - radius, origin.x + radius + 1):
				for y in range(origin.y - radius, origin.y + radius + 1):
					var candidate := Vector2i(x, y)
					if abs(candidate.x - origin.x) != radius and abs(candidate.y - origin.y) != radius:
						continue
					candidates.append(candidate)

		candidates = _sort_cells_by_distance(candidates, from_cell)
		for candidate in candidates:
			if not is_walkable_land_cell(candidate):
				continue
			if path_checks >= MAX_REACHABILITY_PATH_CHECKS:
				return origin
			path_checks += 1
			var path: Array[Vector2i] = get_path_cells(from_cell, candidate)
			if not path.is_empty() or from_cell == candidate:
				return candidate

	return origin

func _sort_cells_by_distance(cells: Array[Vector2i], from_cell: Vector2i) -> Array[Vector2i]:
	var sorted_cells: Array[Vector2i] = cells.duplicate()
	sorted_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_distance: int = abs(a.x - from_cell.x) + abs(a.y - from_cell.y)
		var b_distance: int = abs(b.x - from_cell.x) + abs(b.y - from_cell.y)
		if a_distance == b_distance:
			return abs(a.x - from_cell.x) < abs(b.x - from_cell.x)
		return a_distance < b_distance
	)
	return sorted_cells

func reset_map_cells(map_region: Rect2i, ground_walkable_cells: Array[Vector2i], water_surface_cells: Array[Vector2i] = [], obstacle_cells: Array[Vector2i] = [], resource_cells: Array[Vector2i] = []) -> void:
	if grid == null:
		return
	if map_region.size.x <= 0 or map_region.size.y <= 0:
		map_region = DEFAULT_GRID_REGION

	_configure_grid(map_region)

	ground_cells.clear()
	water_cells.clear()
	obstacle_blocked_cells.clear()
	resource_blocked_cells.clear()

	for x in range(grid.region.position.x, grid.region.end.x):
		for y in range(grid.region.position.y, grid.region.end.y):
			grid.set_point_solid(Vector2i(x, y), true)

	for cell in ground_walkable_cells:
		ground_cells[cell] = true
		set_cell_solid(cell, false)

	for cell in water_surface_cells:
		water_cells[cell] = true
		set_cell_solid(cell, true)

	for cell in obstacle_cells:
		obstacle_blocked_cells[cell] = true
		set_cell_solid(cell, true)

	for cell in resource_cells:
		resource_blocked_cells[cell] = true
		set_cell_solid(cell, true)
