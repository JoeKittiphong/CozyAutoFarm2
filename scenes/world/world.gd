extends Node2D

@onready var ground_layer: Node2D = $GroundLayer
@onready var farm_layer: Node2D = $FarmLayer
@onready var highlight_rect: ColorRect = $HighlightRect
@onready var _farm_manager: Node = get_node("/root/FarmManager")
@onready var _inventory_manager: Node = get_node("/root/InventoryManager")
@onready var _job_manager: Node = get_node("/root/JobManager")

const TILE_SIZE = 128

func _ready() -> void:
	highlight_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	highlight_rect.color = Color(1, 1, 1, 0.3)
	_generate_initial_grass()
	_spawn_worker_system()

	var hud_scene = load("res://scenes/ui/hud.tscn")
	if hud_scene:
		var hud = hud_scene.instantiate()
		add_child(hud)

func _spawn_worker_system() -> void:
	var house_pos = Vector2i(-2, -2)
	_spawn_sprite(farm_layer, house_pos, "res://assets/sprites/worker_house.png", Color.BROWN)
	GridManager.set_cell_solid(house_pos, true)

	var shop_pos = Vector2i(-6, -2)
	_spawn_sprite(farm_layer, shop_pos, "res://assets/sprites/shop_building.png", Color.BROWN)
	GridManager.set_cell_solid(shop_pos, true)

	_spawn_worker()

func _spawn_worker() -> void:
	var WorkerScript = load("res://entities/worker/worker.gd")
	var worker_node = WorkerScript.new()
	worker_node.position = Vector2(-2 * TILE_SIZE, -1 * TILE_SIZE)
	worker_node.position.x += randf_range(-15, 15)
	worker_node.position.y += randf_range(-15, 15)
	add_child(worker_node)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		var grid_pos = _get_grid_position(mouse_pos)
		highlight_rect.global_position = grid_pos * TILE_SIZE
	elif event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var grid_pos = Vector2i(_get_grid_position(mouse_pos))
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(grid_pos)

func _get_grid_position(world_pos: Vector2) -> Vector2:
	return Vector2(floor(world_pos.x / TILE_SIZE), floor(world_pos.y / TILE_SIZE))

func _handle_left_click(grid_pos: Vector2i) -> void:
	if grid_pos.x >= -2 and grid_pos.x <= -1 and grid_pos.y >= -2 and grid_pos.y <= -1:
		var hud = get_node_or_null("HUD")
		if hud:
			hud.toggle_worker_house()
		return

	if grid_pos == Vector2i(-6, -2):
		var hud = get_node_or_null("HUD")
		if hud:
			hud.toggle_shop()
		return

	if _farm_manager.get_tile_state(grid_pos) == _farm_manager.TileState.EMPTY:
		_place_available_blueprint(grid_pos, _inventory_manager, _farm_manager)
	else:
		var hud = get_node_or_null("HUD")
		if hud:
			hud.open_upgrade_ui(grid_pos)

func _place_available_blueprint(grid_pos: Vector2i, inv: Node, f_manager: Node) -> void:
	for blueprint_type in GameData.get_blueprint_order():
		if inv.get_blueprint_stock(blueprint_type) < 1:
			continue

		if not inv.consume_blueprint(blueprint_type):
			return

		var blueprint_def := GameData.get_blueprint_def(blueprint_type)
		if blueprint_def == null:
			return

		if blueprint_def.placement_type == "CROP":
			var crop_type: String = GameData.ITEM_WHEAT
			if blueprint_def.crop_type != "":
				crop_type = blueprint_def.crop_type
			f_manager.place_blueprint(grid_pos, crop_type)
			update_tile_visual(grid_pos, "BLUEPRINT", "res://assets/sprites/dirt.png")
		else:
			var tile_type: String = blueprint_def.tile_type
			if blueprint_def.placement_type == "PROCESSOR":
				var processor_type: String = blueprint_def.processor_type
				if processor_type == GameData.PROCESSOR_MILL:
					inv.mill_count += 1
				f_manager.register_processor(grid_pos, processor_type)
				tile_type = processor_type
			else:
				f_manager.register_building(grid_pos, tile_type)

			update_tile_visual(grid_pos, tile_type, blueprint_def.texture_path)
			GridManager.set_cell_solid(grid_pos, false)
		return

func has_empty_pen(pen_type: String) -> bool:
	for cell in _farm_manager._farm_data.keys():
		if _farm_manager.get_tile_type(cell) != pen_type:
			continue
		var has_animal := false
		for animal_def in GameData.get_animal_defs_for_pen(pen_type):
			for animal in get_tree().get_nodes_in_group(animal_def.group_name):
				if animal.home_pos == cell:
					has_animal = true
					break
			if has_animal:
				break
		if not has_animal:
			return true
	return false

func _spawn_animal_at_shop(type: String) -> void:
	var animal_def := GameData.get_animal_def(type)
	if animal_def == null:
		return
	var AnimalScript = load(animal_def.script_path)
	if AnimalScript:
		var animal = AnimalScript.new()
		animal.animal_type = type
		animal.position = Vector2(-6 * TILE_SIZE, -1 * TILE_SIZE)
		animal.state = GameData.STATE_WAITING_DELIVERY
		add_child(animal)
		if _job_manager:
			_job_manager.add_job(GameData.JOB_FETCH_ANIMAL, Vector2i(-6, -1), {"animal_node": animal, "animal_type": type})

func update_tile_visual(grid_pos: Vector2i, state_name: String, tex_path: String) -> void:
	var node_name = "Tile_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	var tile = farm_layer.get_node_or_null(node_name)

	if tex_path == "" or tex_path.contains("blueprint_indicator"):
		if tile != null:
			tile.modulate = Color(1, 1, 1, 0.5)
			var tex = ResourceLoader.load("res://assets/sprites/dirt.png")
			if tex:
				tile.texture = tex
				var t_size = tex.get_size()
				tile.scale = Vector2(TILE_SIZE / t_size.x, TILE_SIZE / t_size.y)
		return

	if tile == null:
		tile = _create_sprite_node(tex_path, Color.WHITE)
		tile.position = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0, grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0)
		tile.name = node_name
		farm_layer.add_child(tile)
	else:
		var tex = ResourceLoader.load(tex_path)
		if tex:
			tile.texture = tex
			var t_size = tex.get_size()
			tile.scale = Vector2(TILE_SIZE / t_size.x, TILE_SIZE / t_size.y)
			if "crop" in tex_path or "sprout" in tex_path or "ready" in tex_path:
				tile.scale *= 0.6

	if state_name == "BLUEPRINT":
		tile.modulate = Color(1, 1, 1, 0.5)
	else:
		tile.modulate = Color(1, 1, 1, 1.0)

func _create_sprite_node(texture_path: String, fallback_color: Color) -> Sprite2D:
	var sprite = Sprite2D.new()
	var tex = ResourceLoader.load(texture_path)

	if tex == null:
		var fallback = GradientTexture2D.new()
		fallback.width = TILE_SIZE
		fallback.height = TILE_SIZE
		fallback.fill_to = Vector2(1, 1)
		var grad = Gradient.new()
		grad.set_color(0, fallback_color)
		grad.set_color(1, fallback_color.darkened(0.2))
		if "crop" in texture_path:
			fallback.width = int(TILE_SIZE * 0.6)
			fallback.height = int(TILE_SIZE * 0.6)
		fallback.gradient = grad
		tex = fallback
		sprite.texture = tex
	else:
		sprite.texture = tex
		var t_size = tex.get_size()
		sprite.scale = Vector2(TILE_SIZE / t_size.x, TILE_SIZE / t_size.y)
		if "crop" in texture_path:
			sprite.scale *= 0.6
		if "worker_house" in texture_path:
			sprite.scale *= 2.0
			sprite.position -= Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

	return sprite

func _spawn_sprite(parent: Node2D, grid_pos: Vector2i, texture_path: String, fallback_color: Color) -> void:
	var sprite = _create_sprite_node(texture_path, fallback_color)
	sprite.position = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0, grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0)
	parent.add_child(sprite)

func _generate_initial_grass() -> void:
	for x in range(-15, 15):
		for y in range(-10, 10):
			_spawn_sprite(ground_layer, Vector2i(x, y), "res://assets/sprites/grass.png", Color.DARK_GREEN)

