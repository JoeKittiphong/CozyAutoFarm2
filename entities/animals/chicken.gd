extends Node2D
class_name Chicken

@export var move_speed: float = 30.0
const TILE_SIZE = 128

var home_pos: Vector2i
var state: String = "WAITING_DELIVERY" # WAITING_DELIVERY, HUNGRY, WANDERING_FED, EGG_READY
var _timer: float = 0.0
const EGG_TIME: float = 10.0

var target_wander: Vector2
var has_requested_feed: bool = false
var has_requested_collect: bool = false

@onready var sprite: Sprite2D = Sprite2D.new()

func _ready() -> void:
	var tex = ResourceLoader.load("res://assets/sprites/chicken.png")
	if tex:
		sprite.texture = tex
		var t_size = tex.get_size()
		sprite.scale = Vector2(TILE_SIZE / t_size.x, TILE_SIZE / t_size.y) * 0.4
	
	sprite.position = Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)
	add_child(sprite)
	add_to_group("chickens")
	
	# Wait for setup to wander normally.

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
				job_manager.add_job("FEED_CHICKEN", home_pos)
			has_requested_feed = true
			
		_wander(delta) # Slow idle wander while hungry
		
	elif state == "WANDERING_FED":
		_timer -= delta
		if _timer <= 0.0:
			state = "EGG_READY"
			has_requested_collect = false
			
		_wander(delta)
		
	elif state == "EGG_READY":
		if not has_requested_collect:
			var job_manager = get_node_or_null("/root/JobManager")
			if job_manager:
				job_manager.add_job("COLLECT_EGG", home_pos)
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
	target_wander = world_home + Vector2(randf_range(10, TILE_SIZE-10), randf_range(10, TILE_SIZE-10))

func feed() -> void:
	if state == "HUNGRY":
		state = "WANDERING_FED"
		_timer = EGG_TIME
		has_requested_feed = false
		
func collect_egg() -> void:
	if state == "EGG_READY":
		state = "HUNGRY"
		has_requested_collect = false
