extends Node2D

@onready var ground_layer: Node2D = $GroundLayer
@onready var farm_layer: Node2D = $FarmLayer
@onready var highlight_rect: ColorRect = $HighlightRect



const TILE_SIZE = 128

func _ready() -> void:
	highlight_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	highlight_rect.color = Color(1, 1, 1, 0.3) # Semi-transparent white
	_generate_initial_grass()
	_spawn_worker_system()
	
	var hud_script = load("res://scenes/ui/hud.gd")
	if hud_script:
		var hud = hud_script.new()
		hud.name = "HUD"
		add_child(hud)

func _spawn_worker_system() -> void:
	# Spawn house at grid pos (-2, -2)
	var house_pos = Vector2i(-2, -2)
	_spawn_sprite(farm_layer, house_pos, "res://assets/sprites/worker_house.png", Color.BROWN)
	GridManager.set_cell_solid(house_pos, true)
	
	# Spawn Mill building removed (now purchasable)
	pass
	
	# Spawn Shop building at (-6, -2)
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
		# Snap highlight to grid
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
	# Check interactions
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

	var f_manager = get_node("/root/FarmManager")
	var inv = get_node("/root/InventoryManager")
	if f_manager.get_tile_state(grid_pos) == f_manager.TileState.EMPTY:
		if inv.bp_wheat > 0:
			inv.bp_wheat -= 1
			inv.resources_updated.emit()
			f_manager.place_blueprint(grid_pos)
			update_tile_visual(grid_pos, "BLUEPRINT", "res://assets/sprites/dirt.png")
		elif inv.bp_coop > 0:
			inv.bp_coop -= 1
			inv.resources_updated.emit()
			f_manager._farm_data[grid_pos] = f_manager.TileState.COOP
			update_tile_visual(grid_pos, "COOP", "res://assets/sprites/chicken_coop.png")
			GridManager.set_cell_solid(grid_pos, false)
		elif inv.bp_cow_pen > 0:
			inv.bp_cow_pen -= 1
			inv.resources_updated.emit()
			f_manager._farm_data[grid_pos] = f_manager.TileState.COW_PEN
			update_tile_visual(grid_pos, "COW_PEN", "res://assets/sprites/cow_pen.png")
			GridManager.set_cell_solid(grid_pos, false)
		elif inv.bp_bakery > 0:
			inv.bp_bakery -= 1
			inv.resources_updated.emit()
			f_manager.register_bakery(grid_pos)
			update_tile_visual(grid_pos, "BAKERY", "res://assets/sprites/bakery_final.png")
			GridManager.set_cell_solid(grid_pos, false)
		elif inv.bp_tomato > 0:
			inv.bp_tomato -= 1
			inv.resources_updated.emit()
			f_manager.place_blueprint(grid_pos, "TOMATO")
			update_tile_visual(grid_pos, "BLUEPRINT", "res://assets/sprites/dirt.png")
		elif inv.bp_potato > 0:
			inv.bp_potato -= 1
			inv.resources_updated.emit()
			f_manager.place_blueprint(grid_pos, "POTATO")
			update_tile_visual(grid_pos, "BLUEPRINT", "res://assets/sprites/dirt.png")
		elif inv.bp_mill > 0:
			inv.bp_mill -= 1
			inv.mill_count += 1
			inv.resources_updated.emit()
			f_manager.register_mill(grid_pos)
			update_tile_visual(grid_pos, "MILL", "res://assets/sprites/mill_building.png")
			GridManager.set_cell_solid(grid_pos, false)
	else:
		# If cell is not empty, try opening upgrade menu if it's a valid building/plot
		var hud = get_node_or_null("HUD")
		if hud:
			hud.open_upgrade_ui(grid_pos)

func has_empty_pen(pen_type: String) -> bool:
	var f_manager = get_node("/root/FarmManager")
	var target_state = f_manager.TileState.COOP if pen_type == "COOP" else f_manager.TileState.COW_PEN
	for cell in f_manager._farm_data.keys():
		if f_manager.get_tile_state(cell) == target_state:
			var has_animal = false
			var g = "chickens" if pen_type == "COOP" else "cows"
			for a in get_tree().get_nodes_in_group(g):
				if a.home_pos == cell:
					has_animal = true
					break
			if not has_animal:
				return true
	return false

func _spawn_animal_at_shop(type: String) -> void:
	var script_path = "res://entities/animals/" + ("chicken.gd" if type == "CHICKEN" else "cow.gd")
	var AnimalScript = load(script_path)
	if AnimalScript:
		var animal = AnimalScript.new()
		animal.position = Vector2(-6 * TILE_SIZE, -1 * TILE_SIZE) 
		animal.state = "WAITING_DELIVERY"
		add_child(animal)
		
		var job_manager = get_node_or_null("/root/JobManager")
		if job_manager:
			job_manager.add_job("FETCH_ANIMAL", Vector2i(-6, -1), {"animal_node": animal, "animal_type": type})

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
		tile.position = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE/2.0, grid_pos.y * TILE_SIZE + TILE_SIZE/2.0)
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
		fallback.fill_to = Vector2(1,1)
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
		# Scale down automatically to fit TILE_SIZE since generator images might be large
		var t_size = tex.get_size()
		sprite.scale = Vector2(TILE_SIZE / t_size.x, TILE_SIZE / t_size.y)
		if "crop" in texture_path:
			sprite.scale *= 0.6
		if "worker_house" in texture_path:
			sprite.scale *= 2.0 # Make house slightly bigger (2x2 tiles)
			sprite.position -= Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0) # Adjust origin for bigger house
			
	return sprite

func _spawn_sprite(parent: Node2D, grid_pos: Vector2i, texture_path: String, fallback_color: Color) -> void:
	var sprite = _create_sprite_node(texture_path, fallback_color)
	sprite.position = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE/2.0, grid_pos.y * TILE_SIZE + TILE_SIZE/2.0)
	parent.add_child(sprite)

func _generate_initial_grass() -> void:
	for x in range(-15, 15):
		for y in range(-10, 10):
			_spawn_sprite(ground_layer, Vector2i(x, y), "res://assets/sprites/grass.png", Color.DARK_GREEN)
