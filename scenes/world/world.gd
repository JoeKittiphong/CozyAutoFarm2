extends Node2D

const MapScannerClass = preload("res://systems/grid/map_scanner.gd")
const TILE_SIZE := 128
const DEFAULT_MAP_RECT := Rect2i(-15, -10, 30, 20)
const GROUND_SOURCE_ID := 0
const GROUND_ATLAS_COORDS := Vector2i.ZERO
const START_CAMERA_LEFT_UI_WIDTH := 360.0

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var water_layer: TileMapLayer = $WaterLayer
@onready var obstacles_layer: TileMapLayer = $ObstaclesLayer
@onready var resource_layer: TileMapLayer = $ResourceLayer
@onready var plot_layer: Node2D = $PlotLayer
@onready var pen_layer: Node2D = $PenLayer
@onready var building_layer: Node2D = $BuildingLayer
@onready var water_building_layer: Node2D = $WaterBuildingLayer
@onready var actor_layer: Node2D = $ActorLayer
@onready var game_camera: GameCamera = $GameCamera
@onready var highlight_rect: ColorRect = $HighlightRect
@onready var house_marker: Marker2D = $HouseMarker
@onready var shop_marker: Marker2D = $ShopMarker
@onready var worker_spawn_marker: Marker2D = $WorkerSpawnMarker
@onready var animal_shop_spawn_marker: Marker2D = $AnimalShopSpawnMarker
@onready var _farm_manager: Node = get_node("/root/FarmManager")
@onready var _inventory_manager: Node = get_node("/root/InventoryManager")
@onready var _job_manager: Node = get_node("/root/JobManager")
@onready var _resource_manager: Node = get_node("/root/ResourceManager")

func _ready() -> void:
	highlight_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	highlight_rect.color = Color(1, 1, 1, 0.3)
	_fit_window_to_screen()
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_ensure_default_ground_tiles()
	_scan_editor_map()
	_spawn_worker_system()

	var hud_scene = load("res://scenes/ui/hud.tscn")
	if hud_scene:
		var hud = hud_scene.instantiate()
		add_child(hud)

	call_deferred("_frame_start_camera")

func _ensure_default_ground_tiles() -> void:
	if not ground_layer.get_used_cells().is_empty():
		return

	for x in range(DEFAULT_MAP_RECT.position.x, DEFAULT_MAP_RECT.end.x):
		for y in range(DEFAULT_MAP_RECT.position.y, DEFAULT_MAP_RECT.end.y):
			ground_layer.set_cell(Vector2i(x, y), GROUND_SOURCE_ID, GROUND_ATLAS_COORDS)

func _scan_editor_map() -> void:
	MapScannerClass.apply_layers_to_grid(ground_layer, water_layer, obstacles_layer, resource_layer)
	if _resource_manager != null:
		_resource_manager.register_from_layer(resource_layer)

func _spawn_worker_system() -> void:
	var house_pos: Vector2i = _marker_to_grid(house_marker)
	_spawn_sprite(building_layer, house_pos, "res://assets/sprites/worker_house.png", Color.BROWN)
	GridManager.set_cell_solid(house_pos, true)

	var shop_pos: Vector2i = _marker_to_grid(shop_marker)
	_spawn_sprite(building_layer, shop_pos, "res://assets/sprites/shop_building.png", Color.BROWN)
	GridManager.set_cell_solid(shop_pos, true)

	_spawn_worker()

func _on_viewport_size_changed() -> void:
	call_deferred("_frame_start_camera")

func _fit_window_to_screen() -> void:
	if Engine.is_editor_hint():
		return
	var screen_index: int = DisplayServer.window_get_current_screen()
	var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_index)
	if screen_rect.size.x <= 0 or screen_rect.size.y <= 0:
		return
	DisplayServer.window_set_size(screen_rect.size)
	DisplayServer.window_set_position(screen_rect.position)

func _frame_start_camera() -> void:
	if game_camera == null:
		return
	var world_rect: Rect2 = _get_start_world_rect()
	game_camera.frame_world_rect(world_rect, Vector2(TILE_SIZE * 1.5, TILE_SIZE * 1.5), START_CAMERA_LEFT_UI_WIDTH)

func _get_start_world_rect() -> Rect2:
	var has_any := false
	var min_cell := Vector2i.ZERO
	var max_cell := Vector2i.ZERO

	for layer in [ground_layer, water_layer, obstacles_layer, resource_layer]:
		if layer == null:
			continue
		for cell in layer.get_used_cells():
			if not has_any:
				has_any = true
				min_cell = cell
				max_cell = cell
			else:
				min_cell.x = min(min_cell.x, cell.x)
				min_cell.y = min(min_cell.y, cell.y)
				max_cell.x = max(max_cell.x, cell.x)
				max_cell.y = max(max_cell.y, cell.y)

	for marker in [house_marker, shop_marker, worker_spawn_marker, animal_shop_spawn_marker]:
		var cell := _marker_to_grid(marker)
		if not has_any:
			has_any = true
			min_cell = cell
			max_cell = cell
		else:
			min_cell.x = min(min_cell.x, cell.x)
			min_cell.y = min(min_cell.y, cell.y)
			max_cell.x = max(max_cell.x, cell.x)
			max_cell.y = max(max_cell.y, cell.y)

	if not has_any:
		return Rect2(Vector2.ZERO, Vector2(TILE_SIZE * 8, TILE_SIZE * 6))

	min_cell -= Vector2i(2, 2)
	max_cell += Vector2i(2, 2)
	var top_left := _grid_to_world_top_left(min_cell)
	var bottom_right := _grid_to_world_top_left(max_cell + Vector2i.ONE)
	return Rect2(top_left, bottom_right - top_left)

func _spawn_worker() -> void:
	var worker_script = load("res://entities/worker/worker.gd")
	var worker_node = worker_script.new()
	worker_node.position = _get_safe_spawn_world_position(worker_spawn_marker)
	actor_layer.add_child(worker_node)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		var grid_pos = _get_grid_position(mouse_pos)
		highlight_rect.global_position = _grid_to_world_top_left(grid_pos)
		_update_highlight_feedback(grid_pos)
	elif event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var grid_pos = _get_grid_position(mouse_pos)
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(grid_pos)

func _update_highlight_feedback(grid_pos: Vector2i) -> void:
	var blueprint_def = _get_first_available_blueprint_def()
	if blueprint_def == null:
		highlight_rect.color = Color(1, 1, 1, 0.3)
		return

	if _can_place_blueprint(grid_pos, blueprint_def):
		highlight_rect.color = Color(0, 1, 0, 0.3)
	else:
		highlight_rect.color = Color(1, 0, 0, 0.3)

func _get_first_available_blueprint_def() -> BlueprintDefinition:
	for blueprint_type in GameData.get_blueprint_order():
		if _inventory_manager.get_blueprint_stock(blueprint_type) > 0:
			return GameData.get_blueprint_def(blueprint_type)
	return null

func _get_grid_position(world_pos: Vector2) -> Vector2i:
	var local_pos = ground_layer.to_local(world_pos)
	return ground_layer.local_to_map(local_pos)

func _grid_to_world_center(grid_pos: Vector2i) -> Vector2:
	return ground_layer.to_global(ground_layer.map_to_local(grid_pos))

func _grid_to_world_top_left(grid_pos: Vector2i) -> Vector2:
	return _grid_to_world_center(grid_pos) - Vector2(TILE_SIZE, TILE_SIZE) * 0.5

func _marker_to_grid(marker: Marker2D) -> Vector2i:
	return _get_grid_position(marker.global_position)

func _get_safe_spawn_world_position(marker: Marker2D) -> Vector2:
	var marker_cell: Vector2i = _marker_to_grid(marker)
	var safe_cell: Vector2i = GridManager.find_nearest_walkable_land_cell(marker_cell)
	return _grid_to_world_top_left(safe_cell)

func _is_house_interaction_cell(grid_pos: Vector2i) -> bool:
	var house_origin: Vector2i = _marker_to_grid(house_marker)
	return grid_pos.x >= house_origin.x and grid_pos.x <= house_origin.x + 1 and grid_pos.y >= house_origin.y and grid_pos.y <= house_origin.y + 1

func _is_shop_interaction_cell(grid_pos: Vector2i) -> bool:
	return grid_pos == _marker_to_grid(shop_marker)

func _can_place_blueprint(grid_pos: Vector2i, blueprint_def: BlueprintDefinition) -> bool:
	if blueprint_def == null:
		return false
	if _farm_manager.get_tile_state(grid_pos) != _farm_manager.TileState.EMPTY:
		return false

	var placement_surface: String = blueprint_def.placement_surface
	if placement_surface == "WATER":
		return GridManager.is_buildable_on_water(grid_pos)
	return GridManager.is_buildable_on_land(grid_pos)

func _handle_left_click(grid_pos: Vector2i) -> void:
	if _is_house_interaction_cell(grid_pos):
		var hud = get_node_or_null("HUD")
		if hud:
			hud.toggle_worker_house()
		return

	if _is_shop_interaction_cell(grid_pos):
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

		var blueprint_def: BlueprintDefinition = GameData.get_blueprint_def(blueprint_type)
		if blueprint_def == null:
			continue
		if not _can_place_blueprint(grid_pos, blueprint_def):
			continue
		if not inv.consume_blueprint(blueprint_type):
			return

		if blueprint_def.placement_type == "CROP":
			var crop_type: String = GameData.ITEM_WHEAT
			if blueprint_def.crop_type != "":
				crop_type = blueprint_def.crop_type
			f_manager.place_blueprint(grid_pos, crop_type, blueprint_type)
			update_tile_visual(grid_pos, "BLUEPRINT", "res://assets/sprites/dirt.png")
		else:
			var tile_type: String = blueprint_def.tile_type
			if blueprint_def.placement_type == "PROCESSOR":
				var processor_type: String = blueprint_def.processor_type
				if processor_type == GameData.PROCESSOR_MILL:
					inv.mill_count += 1
				f_manager.register_processor(grid_pos, processor_type, blueprint_type)
			else:
				f_manager.register_building(grid_pos, tile_type, blueprint_type)
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
	var animal_def = GameData.get_animal_def(type)
	if animal_def == null:
		return
	var animal_script = load(animal_def.script_path)
	if animal_script:
		var animal = animal_script.new()
		animal.animal_type = type
		animal.position = _get_safe_spawn_world_position(animal_shop_spawn_marker)
		animal.state = GameData.STATE_WAITING_DELIVERY
		actor_layer.add_child(animal)
		if _job_manager:
			_job_manager.add_job(GameData.JOB_FETCH_ANIMAL, _marker_to_grid(animal_shop_spawn_marker), {"animal_node": animal, "animal_type": type})

func clear_resource_tile(grid_pos: Vector2i) -> void:
	if resource_layer != null:
		resource_layer.erase_cell(grid_pos)

func update_tile_visual(grid_pos: Vector2i, state_name: String, tex_path: String) -> void:
	var node_name = "Tile_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	var tile = _find_tile_visual(node_name)
	var target_layer: Node2D = _get_visual_layer(grid_pos, state_name, tex_path)

	if tex_path == "" or tex_path.contains("blueprint_indicator"):
		if tile != null:
			_move_visual_to_layer(tile, target_layer)
			tile.modulate = Color(1, 1, 1, 0.5)
			var tex = ResourceLoader.load("res://assets/sprites/dirt.png")
			if tex:
				tile.texture = tex
				var t_size = tex.get_size()
				tile.scale = Vector2(TILE_SIZE / t_size.x, TILE_SIZE / t_size.y)
		return

	if tile == null:
		tile = _create_sprite_node(tex_path, Color.WHITE)
		tile.position = _grid_to_world_center(grid_pos)
		tile.name = node_name
		target_layer.add_child(tile)
	else:
		_move_visual_to_layer(tile, target_layer)
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

func _find_tile_visual(node_name: String) -> Sprite2D:
	for layer in [plot_layer, pen_layer, building_layer, water_building_layer]:
		if layer == null:
			continue
		var node = layer.get_node_or_null(node_name)
		if node != null:
			return node as Sprite2D
	return null

func _get_visual_layer(grid_pos: Vector2i, state_name: String, tex_path: String) -> Node2D:
	if state_name == GameData.BLUEPRINT_COOP or state_name == GameData.BLUEPRINT_COW_PEN:
		return pen_layer
	if "coop" in tex_path or "cow_pen" in tex_path:
		return pen_layer
	if state_name == "BLUEPRINT" or "dirt" in tex_path or "sprout" in tex_path or "crop" in tex_path or "ready" in tex_path:
		return plot_layer
	if GridManager.is_water_cell(grid_pos) and water_building_layer != null:
		return water_building_layer
	return building_layer

func _move_visual_to_layer(tile: Sprite2D, target_layer: Node2D) -> void:
	if tile.get_parent() == target_layer:
		return
	var old_position: Vector2 = tile.global_position
	if tile.get_parent() != null:
		tile.get_parent().remove_child(tile)
	target_layer.add_child(tile)
	tile.global_position = old_position

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
		if "crop" in texture_path or "sprout" in texture_path or "ready" in texture_path:
			sprite.scale *= 0.6
		if "worker_house" in texture_path:
			sprite.scale *= 2.0
			sprite.position -= Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

	return sprite

func _spawn_sprite(parent: Node2D, grid_pos: Vector2i, texture_path: String, fallback_color: Color) -> void:
	var sprite = _create_sprite_node(texture_path, fallback_color)
	sprite.position = _grid_to_world_center(grid_pos)
	parent.add_child(sprite)
