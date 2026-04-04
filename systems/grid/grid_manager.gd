extends Node
class_name GridManagerClass

const TILE_SIZE := 128
const MAP_WIDTH := 100
const MAP_HEIGHT := 100

var grid: AStarGrid2D

func _ready() -> void:
    grid = AStarGrid2D.new()
    grid.region = Rect2i(-MAP_WIDTH/2, -MAP_HEIGHT/2, MAP_WIDTH, MAP_HEIGHT)
    grid.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    grid.update()

func get_path_cells(start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]:
    if not grid.is_in_bounds(start_cell.x, start_cell.y) or not grid.is_in_bounds(end_cell.x, end_cell.y):
        return []
    return grid.get_id_path(start_cell, end_cell)

func set_cell_solid(cell: Vector2i, solid: bool) -> void:
    if grid.is_in_bounds(cell.x, cell.y):
        grid.set_point_solid(cell, solid)
