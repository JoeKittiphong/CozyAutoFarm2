extends Node2D
class_name FarmAnimal



@export var animal_type: String = ""

var home_pos: Vector2i
var state: String = GameData.STATE_WAITING_DELIVERY
var _timer: float = 0.0
var target_wander: Vector2
var has_requested_feed: bool = false
var has_requested_collect: bool = false

@onready var sprite: Sprite2D = Sprite2D.new()
@onready var _job_manager: Node = get_node("/root/JobManager")
@onready var _inventory_manager: Node = get_node("/root/InventoryManager")

func _ready() -> void:
	add_child(sprite)
	_apply_definition()

func _process(delta: float) -> void:
	var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
	if animal_def == null:
		return

	if state == GameData.STATE_WAITING_DELIVERY:
		return

	if state == GameData.STATE_HUNGRY:
		if not has_requested_feed:
			_request_feed_job(animal_def)
			has_requested_feed = true
		_wander(delta, animal_def)
		return

	if state == GameData.STATE_WANDERING_FED:
		_timer -= delta
		if _timer <= 0.0:
			state = animal_def.ready_state_name
			has_requested_collect = false
		_wander(delta, animal_def)
		return

	if state == animal_def.ready_state_name and not has_requested_collect:
		if _job_manager:
			_job_manager.add_job(GameData.JOB_COLLECT_ANIMAL_PRODUCT, home_pos, {
				"item_type": animal_def.product_item_id,
				"output_item_type": animal_def.product_item_id,
				"group_name": animal_def.group_name,
				"collect_method": "collect_product",
			})
		has_requested_collect = true

func setup(grid_pos: Vector2i) -> void:
	home_pos = grid_pos
	position = Vector2(home_pos.x * GameData.TILE_SIZE, home_pos.y * GameData.TILE_SIZE)
	state = GameData.STATE_HUNGRY
	_pick_new_wander_target(GameData.get_animal_def(animal_type))

func feed() -> void:
	var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
	if animal_def == null:
		return
	if state == GameData.STATE_HUNGRY:
		state = GameData.STATE_WANDERING_FED
		_timer = animal_def.produce_time
		has_requested_feed = false

func collect_product() -> void:
	var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
	if animal_def == null:
		return
	if state == animal_def.ready_state_name:
		state = GameData.STATE_HUNGRY
		has_requested_collect = false

func _request_feed_job(animal_def: AnimalDefinition) -> void:
	if _job_manager == null:
		return

	var use_premium_feed: bool = _inventory_manager != null and _inventory_manager.get_item_stock(GameData.ITEM_ANIMAL_FEED) > 0
	var requested_item: String = GameData.ITEM_ANIMAL_FEED if use_premium_feed else animal_def.feed_item_id
	var requested_amount: int = 1 if use_premium_feed else animal_def.feed_amount
	_job_manager.add_job(GameData.JOB_FEED_ANIMAL, home_pos, {
		"item_type": requested_item,
		"amount": requested_amount,
		"group_name": animal_def.group_name,
		"fallback_item_type": animal_def.feed_item_id,
		"fallback_amount": animal_def.feed_amount,
		"feed_points": animal_def.premium_feed_points,
		"output_item_type": animal_def.product_item_id,
	})

func _wander(delta: float, animal_def: AnimalDefinition) -> void:
	var dir = (target_wander - position).normalized()
	var dist = position.distance_to(target_wander)
	if dist < 5.0:
		_pick_new_wander_target(animal_def)
	else:
		position += dir * animal_def.move_speed * delta

func _pick_new_wander_target(animal_def: AnimalDefinition) -> void:
	if animal_def == null:
		return
	var world_home = Vector2(home_pos) * GameData.TILE_SIZE
	var padding: float = animal_def.wander_padding
	target_wander = world_home + Vector2(randf_range(padding, GameData.TILE_SIZE - padding), randf_range(padding, GameData.TILE_SIZE - padding))

func _apply_definition() -> void:
	var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
	if animal_def == null:
		return

	if animal_def.group_name != "" and not is_in_group(animal_def.group_name):
		add_to_group(animal_def.group_name)

	var tex = ResourceLoader.load(animal_def.icon_path)
	if tex:
		sprite.texture = tex
		var t_size = tex.get_size()
		sprite.scale = Vector2(GameData.TILE_SIZE / t_size.x, GameData.TILE_SIZE / t_size.y) * animal_def.sprite_scale
	sprite.position = Vector2(GameData.TILE_SIZE / 2.0, GameData.TILE_SIZE / 2.0)

func update_visual(level: int) -> void:
	var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
	if animal_def == null:
		return

	var tex_path: String = GameData.get_animal_level_texture(animal_type, level)
	var tex = ResourceLoader.load(tex_path)
	if tex:
		sprite.texture = tex
		var t_size = tex.get_size()
		sprite.scale = Vector2(GameData.TILE_SIZE / t_size.x, GameData.TILE_SIZE / t_size.y) * animal_def.sprite_scale

