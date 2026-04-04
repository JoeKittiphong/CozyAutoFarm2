extends Node2D
class_name Cow

@export var move_speed: float = 20.0
const TILE_SIZE = 128

var home_pos: Vector2i
var state: String = "WAITING_DELIVERY"
var _timer: float = 0.0
const PRODUCE_TIME: float = 15.0

var target_wander: Vector2
var has_requested_feed: bool = false
var has_requested_collect: bool = false

@onready var sprite: Sprite2D = Sprite2D.new()

func _ready() -> void:
    var tex = ResourceLoader.load("res://assets/sprites/cow.png")
    if tex:
        sprite.texture = tex
        var t_size = tex.get_size()
        sprite.scale = Vector2(TILE_SIZE / t_size.x, TILE_SIZE / t_size.y) * 0.7
    
    sprite.position = Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)
    add_child(sprite)
    add_to_group("cows")

func setup(grid_pos: Vector2i) -> void:
    home_pos = grid_pos
    position = Vector2(home_pos.x * TILE_SIZE, home_pos.y * TILE_SIZE)
    state = "HUNGRY"
    _pick_new_wander_target()

func _process(delta: float) -> void:
    if state == "WAITING_DELIVERY":
        return

    if state == "HUNGRY":
        if not has_requested_feed:
            var job_manager = get_node_or_null("/root/JobManager")
            if job_manager:
                job_manager.add_job("FEED_COW", home_pos)
            has_requested_feed = true
        _wander(delta)
        
    elif state == "WANDERING_FED":
        _timer -= delta
        if _timer <= 0.0:
            state = "MILK_READY"
            has_requested_collect = false
        _wander(delta)
        
    elif state == "MILK_READY":
        if not has_requested_collect:
            var job_manager = get_node_or_null("/root/JobManager")
            if job_manager:
                job_manager.add_job("COLLECT_MILK", home_pos)
            has_requested_collect = true

func _wander(delta: float) -> void:
    var dir = (target_wander - position).normalized()
    var dist = position.distance_to(target_wander)
    if dist < 5.0:
        _pick_new_wander_target()
    else:
        position += dir * move_speed * delta

func _pick_new_wander_target() -> void:
    var world_home = Vector2(home_pos) * TILE_SIZE
    target_wander = world_home + Vector2(randf_range(20, TILE_SIZE-20), randf_range(20, TILE_SIZE-20))

func feed() -> void:
    if state == "HUNGRY":
        state = "WANDERING_FED"
        _timer = PRODUCE_TIME
        has_requested_feed = false
        
func collect_milk() -> void:
    if state == "MILK_READY":
        state = "HUNGRY"
        has_requested_collect = false
