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
    TOMATO_SPROUT,
    TOMATO_READY,
    POTATO_SPROUT,
    POTATO_READY,
    COOP,
    COW_PEN,
    BAKERY,
    MILL
}

var _bakery_data: Dictionary = {}
const BAKE_TIME: float = 15.0

var _mill_data: Dictionary = {}
const GRIND_TIME: float = 5.0

var _farm_data: Dictionary = {}
var _growth_time: Dictionary = {}
const TIME_TO_GROW = 30.0 # user requested 30 seconds

func _process(delta: float) -> void:
    for cell in _farm_data.keys():
        var state = get_tile_state(cell)
        if state == TileState.GROWING:
            if _growth_time.has(cell):
                _growth_time[cell] -= delta
                if _growth_time[cell] <= 0.0:
                    _farm_data[cell].state = TileState.READY_TO_HARVEST
                    _growth_time.erase(cell)
                    get_node("/root/JobManager").add_job("HARVEST", cell)
                    
                    var crop_type = get_tile_type(cell)
                    var ready_tex = "res://assets/sprites/wheat_ready.png"
                    if crop_type == "TOMATO": ready_tex = "res://assets/sprites/tomato_ready.png"
                    elif crop_type == "POTATO": ready_tex = "res://assets/sprites/potato_ready.png"
                    
                    _notify_world_visual(cell, "READY", ready_tex)
        
        elif state == TileState.BAKERY:
            var data = _bakery_data.get(cell)
            if data and data.state == "BAKING":
                data.timer -= delta
                if data.timer <= 0.0:
                    data.state = "READY"
                    get_node("/root/JobManager").add_job("COLLECT_CAKE", cell)
                    _notify_world_visual(cell, "CAKE_READY", "res://assets/sprites/bakery_final.png")
            elif data and data.state == "WAITING":
                _request_bakery_ingredients(cell)
        
        elif state == TileState.MILL:
            var m_data = _mill_data.get(cell)
            if m_data and m_data.state == "GRINDING":
                m_data.timer -= delta
                if m_data.timer <= 0.0:
                    m_data.state = "READY"
                    get_node("/root/JobManager").add_job("COLLECT_FLOUR", cell)
                    _notify_world_visual(cell, "FLOUR_READY", "res://assets/sprites/mill_building.png")
            elif m_data and m_data.state == "WAITING":
                _request_mill_ingredients(cell)

func place_blueprint(cell: Vector2i, crop_type: String = "WHEAT") -> void:
    if get_tile_state(cell) == TileState.EMPTY:
        _farm_data[cell] = {
            "state": TileState.BLUEPRINT,
            "type": crop_type
        }
        get_node("/root/JobManager").add_job("TILL", cell)

func complete_till(cell: Vector2i) -> void:
    if _farm_data.has(cell) and _farm_data[cell] == TileState.BLUEPRINT:
        _farm_data[cell] = TileState.TILLED
        get_node("/root/JobManager").add_job("PLANT", cell)
        _notify_world_visual(cell, "TILLED", "res://assets/sprites/dirt.png")

func complete_plant(cell: Vector2i) -> void:
    if _farm_data.has(cell) and get_tile_state(cell) == TileState.TILLED:
        _farm_data[cell].state = TileState.PLANTED
        get_node("/root/JobManager").add_job("WATER", cell)
        
        var crop_type = get_tile_type(cell)
        var sprout_tex = "res://assets/sprites/wheat_sprout.png"
        if crop_type == "TOMATO": sprout_tex = "res://assets/sprites/tomato_sprout.png"
        elif crop_type == "POTATO": sprout_tex = "res://assets/sprites/potato_sprout.png"
        
        _notify_world_visual(cell, "PLANTED", sprout_tex)

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
        if _farm_data[cell] is Dictionary:
            return _farm_data[cell].state
        return _farm_data[cell]
    return TileState.EMPTY

func get_tile_type(cell: Vector2i) -> String:
    if _farm_data.has(cell) and _farm_data[cell] is Dictionary:
        return _farm_data[cell].type
    return "WHEAT" # Default for old tiles

func _notify_world_visual(cell: Vector2i, state_name: String, tex_path: String) -> void:
    var world = get_node_or_null("/root/World")
    if world != null:
        world.update_tile_visual(cell, state_name, tex_path)

func register_bakery(cell: Vector2i) -> void:
    _farm_data[cell] = TileState.BAKERY
    _bakery_data[cell] = {
        "flour": 0, "egg": 0, "milk": 0,
        "state": "WAITING", "timer": 0.0,
        "jobs_requested": []
    }

func register_mill(cell: Vector2i) -> void:
    _farm_data[cell] = TileState.MILL
    _mill_data[cell] = {
        "wheat": 0,
        "state": "WAITING", "timer": 0.0,
        "jobs_requested": false
    }

func _request_mill_ingredients(cell: Vector2i) -> void:
    var data = _mill_data[cell]
    if data.wheat < 3 and not data.jobs_requested:
        get_node("/root/JobManager").add_job("MILL_DELIVER_WHEAT", cell)
        data.jobs_requested = true

func deliver_wheat_to_mill(cell: Vector2i) -> void:
    if not _mill_data.has(cell): return
    var data = _mill_data[cell]
    data.wheat += 3 # Current worker logic delivers 3 at once
    data.jobs_requested = false
    if data.wheat >= 3:
        data.state = "GRINDING"
        data.timer = GRIND_TIME

func collect_flour_from_mill(cell: Vector2i) -> void:
    if not _mill_data.has(cell): return
    var data = _mill_data[cell]
    if data.state == "READY":
        data.wheat -= 3
        data.state = "WAITING"
        data.timer = 0.0

func _request_bakery_ingredients(cell: Vector2i) -> void:
    var data = _bakery_data[cell]
    var jm = get_node("/root/JobManager")
    
    if data.flour == 0 and not "FLOUR" in data.jobs_requested:
        jm.add_job("BAKERY_DELIVER_FLOUR", cell)
        data.jobs_requested.append("FLOUR")
    if data.egg == 0 and not "EGG" in data.jobs_requested:
        jm.add_job("BAKERY_DELIVER_EGG", cell)
        data.jobs_requested.append("EGG")
    if data.milk == 0 and not "MILK" in data.jobs_requested:
        jm.add_job("BAKERY_DELIVER_MILK", cell)
        data.jobs_requested.append("MILK")

func deliver_to_bakery(cell: Vector2i, type: String) -> void:
    if not _bakery_data.has(cell): return
    var data = _bakery_data[cell]
    
    if type == "FLOUR": data.flour = 1
    elif type == "EGG": data.egg = 1
    elif type == "MILK": data.milk = 1
    
    if type in data.jobs_requested:
        data.jobs_requested.erase(type)
        
    if data.flour == 1 and data.egg == 1 and data.milk == 1:
        data.state = "BAKING"
        data.timer = BAKE_TIME

func collect_cake_from_bakery(cell: Vector2i) -> void:
    if not _bakery_data.has(cell): return
    var data = _bakery_data[cell]
    if data.state == "READY":
        data.flour = 0
        data.egg = 0
        data.milk = 0
        data.state = "WAITING"
        data.timer = 0.0
        # Bakery logic in process will request new ingredients next frame
