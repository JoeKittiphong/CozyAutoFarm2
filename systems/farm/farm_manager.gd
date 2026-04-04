extends Node
class_name FarmManagerClass

enum TileState {
    EMPTY,
    BLUEPRINT,
    TILLED,
    PLANTED,
    WATERED,
    GROWING,
    READY_TO_HARVEST,
    COOP,
    COW_PEN
}

var _farm_data: Dictionary = {}
var _growth_time: Dictionary = {}
const TIME_TO_GROW = 30.0 # user requested 30 seconds

func _process(delta: float) -> void:
    for cell in _farm_data.keys():
        if _farm_data[cell] == TileState.GROWING:
            if _growth_time.has(cell):
                _growth_time[cell] -= delta
                if _growth_time[cell] <= 0.0:
                    _farm_data[cell] = TileState.READY_TO_HARVEST
                    _growth_time.erase(cell)
                    get_node("/root/JobManager").add_job("HARVEST", cell)
                    _notify_world_visual(cell, "READY", "res://assets/sprites/wheat_ready.png")

func place_blueprint(cell: Vector2i) -> void:
    if get_tile_state(cell) == TileState.EMPTY:
        _farm_data[cell] = TileState.BLUEPRINT
        get_node("/root/JobManager").add_job("TILL", cell)

func complete_till(cell: Vector2i) -> void:
    if _farm_data.has(cell) and _farm_data[cell] == TileState.BLUEPRINT:
        _farm_data[cell] = TileState.TILLED
        get_node("/root/JobManager").add_job("PLANT", cell)
        _notify_world_visual(cell, "TILLED", "res://assets/sprites/dirt.png")

func complete_plant(cell: Vector2i) -> void:
    if _farm_data.has(cell) and _farm_data[cell] == TileState.TILLED:
        _farm_data[cell] = TileState.PLANTED
        get_node("/root/JobManager").add_job("WATER", cell)
        _notify_world_visual(cell, "PLANTED", "res://assets/sprites/wheat_sprout.png")

func complete_water(cell: Vector2i) -> void:
    # We can visualize watering by dimming the tile, but for now just kickstart growth
    if _farm_data.has(cell) and _farm_data[cell] == TileState.PLANTED:
        _farm_data[cell] = TileState.GROWING
        _growth_time[cell] = TIME_TO_GROW

func complete_harvest(cell: Vector2i) -> void:
    if _farm_data.has(cell) and _farm_data[cell] == TileState.READY_TO_HARVEST:
        _farm_data[cell] = TileState.BLUEPRINT # Auto Loop back to start!
        get_node("/root/JobManager").add_job("TILL", cell)
        _notify_world_visual(cell, "HARVESTED", "res://assets/sprites/blueprint_indicator.png") # Special case to clear visuals or return to blueprint

func get_tile_state(cell: Vector2i) -> int:
    if _farm_data.has(cell):
        return _farm_data[cell]
    return TileState.EMPTY

func _notify_world_visual(cell: Vector2i, state_name: String, tex_path: String) -> void:
    var world = get_node_or_null("/root/World")
    if world != null:
        world.update_tile_visual(cell, state_name, tex_path)
