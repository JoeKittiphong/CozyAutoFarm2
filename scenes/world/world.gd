extends Node2D

const MapScannerClass = preload("res://systems/grid/map_scanner.gd")

const DEFAULT_MAP_RECT := Rect2i(-15, -10, 30, 20)
const GROUND_SOURCE_ID := 0
const GROUND_ATLAS_COORDS := Vector2i.ZERO
const START_CAMERA_LEFT_UI_WIDTH := 360.0
const SORT_Z_BASE := 2000

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
@onready var gathering_house_marker: Marker2D = $GatheringHouseMarker
@onready var factory_house_marker: Marker2D = $FactoryHouseMarker
@onready var central_warehouse_marker: Marker2D = $CentralWarehouseMarker
@onready var central_warehouse_storage_marker: Marker2D = $CentralWarehouseStorageMarker
@onready var shop_marker: Marker2D = $ShopMarker
@onready var worker_spawn_marker: Marker2D = $WorkerSpawnMarker
@onready var animal_shop_spawn_marker: Marker2D = $AnimalShopSpawnMarker
@onready var _farm_manager: Node = get_node("/root/FarmManager")
@onready var _inventory_manager: Node = get_node("/root/InventoryManager")
@onready var _job_manager: Node = get_node("/root/JobManager")
@onready var _resource_manager: Node = get_node("/root/ResourceManager")

var _texture_cache: Dictionary = {}

func _ready() -> void:
	# เธเธฑเธเธเธฑเธเธเธเธฒเธ”เธเนเธญเธ TileSet เนเธซเนเธ•เธฃเธเธเธฑเธเธเนเธฒเธเธฅเธฒเธเนเธ GameData
	if ground_layer and ground_layer.tile_set:
		ground_layer.tile_set.tile_size = Vector2i(GameData.TILE_SIZE, GameData.TILE_SIZE)

	highlight_rect.size = Vector2(GameData.TILE_SIZE, GameData.TILE_SIZE)
	highlight_rect.color = Color(1, 1, 1, 0.3)
	_fit_window_to_screen()
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_ensure_default_ground_tiles()
	_scan_editor_map()
	_spawn_starting_structures()

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

func _spawn_starting_structures() -> void:
	var farm_house_cell: Vector2i = _marker_to_grid(house_marker)
	var gathering_house_cell: Vector2i = _marker_to_grid(gathering_house_marker)
	var factory_house_cell: Vector2i = _marker_to_grid(factory_house_marker)
	GameData.set_domain_house_pos(GameData.WORKER_DOMAIN_FARM, farm_house_cell)
	GameData.set_domain_house_pos(GameData.WORKER_DOMAIN_GATHERING, gathering_house_cell)
	GameData.set_domain_house_pos(GameData.WORKER_DOMAIN_FACTORY, factory_house_cell)

	var farm_storage_pos: Vector2i = GridManager.find_nearest_walkable_land_cell(_marker_to_grid(house_marker), 8)
	var gathering_storage_pos: Vector2i = GridManager.find_nearest_walkable_land_cell(_marker_to_grid(gathering_house_marker), 8)
	var factory_storage_pos: Vector2i = GridManager.find_nearest_walkable_land_cell(_marker_to_grid(factory_house_marker), 8)
	GameData.set_domain_storage_pos(GameData.WORKER_DOMAIN_FARM, farm_storage_pos)
	GameData.set_domain_storage_pos(GameData.WORKER_DOMAIN_GATHERING, gathering_storage_pos)
	GameData.set_domain_storage_pos(GameData.WORKER_DOMAIN_FACTORY, factory_storage_pos)

	var default_storage_pos: Vector2i = GridManager.find_nearest_walkable_land_cell(_marker_to_grid(central_warehouse_storage_marker), 8)
	GameData.set_storage_pos(default_storage_pos)
	GameData.set_processing_storage_pos(default_storage_pos)
	GameData.set_has_central_storage(false)
	var shop_pos: Vector2i = _marker_to_grid(shop_marker)
	GameData.set_shop_pos(shop_pos)
	_spawn_sprite(building_layer, shop_pos, "res://assets/sprites/shop_building.png", Color.BROWN)
	_set_structure_solid(shop_pos, true)

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
	game_camera.frame_world_rect(world_rect, Vector2(GameData.TILE_SIZE * 1.5, GameData.TILE_SIZE * 1.5), START_CAMERA_LEFT_UI_WIDTH)

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

	for marker in [gathering_house_marker, factory_house_marker]:
		var extra_cell := _marker_to_grid(marker)
		if not has_any:
			has_any = true
			min_cell = extra_cell
			max_cell = extra_cell
		else:
			min_cell.x = min(min_cell.x, extra_cell.x)
			min_cell.y = min(min_cell.y, extra_cell.y)
			max_cell.x = max(max_cell.x, extra_cell.x)
			max_cell.y = max(max_cell.y, extra_cell.y)

	if not has_any:
		return Rect2(Vector2.ZERO, Vector2(GameData.TILE_SIZE * 8, GameData.TILE_SIZE * 6))

	min_cell -= Vector2i(2, 2)
	max_cell += Vector2i(2, 2)
	var top_left := _grid_to_world_top_left(min_cell)
	var bottom_right := _grid_to_world_top_left(max_cell + Vector2i.ONE)
	return Rect2(top_left, bottom_right - top_left)

func _spawn_worker(domain_id: String = GameData.WORKER_DOMAIN_FARM, preferred_house_cell: Vector2i = Vector2i(-999, -999)) -> void:
	var worker_script = load("res://entities/worker/worker.gd")
	var worker_node = worker_script.new()
	worker_node.set_worker_domain(domain_id)
	worker_node.position = _get_worker_spawn_world_position(domain_id, preferred_house_cell)
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
	return _grid_to_world_center(grid_pos) - Vector2(GameData.TILE_SIZE, GameData.TILE_SIZE) * 0.5

func _marker_to_grid(marker: Marker2D) -> Vector2i:
	return _get_grid_position(marker.global_position)

func _get_safe_spawn_world_position(marker: Marker2D) -> Vector2:
	var marker_cell: Vector2i = _marker_to_grid(marker)
	var safe_cell: Vector2i = GridManager.find_nearest_walkable_land_cell(marker_cell)
	return _grid_to_world_top_left(safe_cell)

func _get_worker_house_info_at_cell(grid_pos: Vector2i) -> Dictionary:
	for cell in _farm_manager._farm_data.keys():
		var tile_type: String = _farm_manager.get_tile_type(cell)
		var domain_id: String = GameData.get_worker_domain_for_house_tile_type(tile_type)
		if domain_id == "":
			continue
		if _is_large_building_hit(cell, grid_pos):
			return {"domain": domain_id, "cell": cell}
	return {}

func _get_worker_spawn_world_position(domain_id: String, preferred_house_cell: Vector2i = Vector2i(-999, -999)) -> Vector2:
	var anchor_cell: Vector2i = _find_worker_house_cell_for_domain(domain_id, preferred_house_cell)
	if anchor_cell != Vector2i(-999, -999):
		var safe_cell: Vector2i = GridManager.find_nearest_walkable_land_cell(anchor_cell)
		return _grid_to_world_top_left(safe_cell)
	return _get_safe_spawn_world_position(worker_spawn_marker)

func _find_worker_house_cell_for_domain(domain_id: String, preferred_house_cell: Vector2i = Vector2i(-999, -999)) -> Vector2i:
	if preferred_house_cell != Vector2i(-999, -999):
		if GameData.get_worker_domain_for_house_tile_type(_farm_manager.get_tile_type(preferred_house_cell)) == domain_id:
			return preferred_house_cell

	var best_cell: Vector2i = Vector2i(-999, -999)
	var best_distance: int = 2147483647
	var shop_cell: Vector2i = _marker_to_grid(shop_marker)
	for cell in _farm_manager._farm_data.keys():
		var tile_type: String = _farm_manager.get_tile_type(cell)
		if GameData.get_worker_domain_for_house_tile_type(tile_type) != domain_id:
			continue
		var distance: int = abs(cell.x - shop_cell.x) + abs(cell.y - shop_cell.y)
		if distance < best_distance:
			best_distance = distance
			best_cell = cell
	return best_cell

func _is_large_building_hit(anchor_cell: Vector2i, grid_pos: Vector2i) -> bool:
	return grid_pos.x >= anchor_cell.x and grid_pos.x <= anchor_cell.x + 1 and grid_pos.y >= anchor_cell.y and grid_pos.y <= anchor_cell.y + 1

func _set_structure_solid(anchor_cell: Vector2i, solid: bool, footprint: Vector2i = Vector2i(2, 2)) -> void:
	for x in range(anchor_cell.x, anchor_cell.x + footprint.x):
		for y in range(anchor_cell.y, anchor_cell.y + footprint.y):
			GridManager.set_cell_solid(Vector2i(x, y), solid)

func _is_shop_interaction_cell(grid_pos: Vector2i) -> bool:
	return grid_pos == GameData.get_shop_pos()

func _is_warehouse_interaction_cell(grid_pos: Vector2i) -> bool:
	for cell in _farm_manager._farm_data.keys():
		if _farm_manager.get_tile_type(cell) == GameData.BLUEPRINT_STORAGE and _is_large_building_hit(cell, grid_pos):
			return true
	return false

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
	var house_info: Dictionary = _get_worker_house_info_at_cell(grid_pos)
	if not house_info.is_empty():
		var hud = get_node_or_null("HUD")
		if hud:
			hud.toggle_worker_house_at(String(house_info.get("domain", "")), Vector2i(house_info.get("cell", Vector2i.ZERO)))
		return

	if _is_shop_interaction_cell(grid_pos):
		var hud = get_node_or_null("HUD")
		if hud:
			hud.toggle_shop()
		return

	if _is_warehouse_interaction_cell(grid_pos):
		var hud = get_node_or_null("HUD")
		if hud:
			hud._toggle_warehouse_panel()
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
				if blueprint_type == GameData.BLUEPRINT_STORAGE:
					var storage_pos: Vector2i = GridManager.find_nearest_walkable_land_cell(grid_pos, 8)
					GameData.set_storage_pos(storage_pos)
					GameData.set_processing_storage_pos(storage_pos)
					GameData.set_has_central_storage(true)
				var domain_id: String = GameData.get_worker_domain_for_house_tile_type(tile_type)
				if domain_id != "":
					GameData.set_domain_house_pos(domain_id, grid_pos)
					var domain_storage_pos: Vector2i = GridManager.find_nearest_walkable_land_cell(grid_pos, 8)
					GameData.set_domain_storage_pos(domain_id, domain_storage_pos)
			_set_structure_solid(grid_pos, true)
		return

func has_empty_pen(pen_type: String) -> bool:
	return _farm_manager.find_empty_pen(pen_type) != Vector2i(-999, -999)

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
			var pickup_pos: Vector2i = _marker_to_grid(animal_shop_spawn_marker)
			_job_manager.add_job(GameData.JOB_FETCH_ANIMAL, pickup_pos, {
				"animal_node": animal,
				"animal_type": type,
				"interaction_pos": pickup_pos,
			})

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
			_apply_sprite_texture_and_layout(tile, grid_pos, state_name, "res://assets/sprites/dirt.png", Color.WHITE)
		return

	if tile == null:
		tile = _create_sprite_node(grid_pos, state_name, tex_path, Color.WHITE)
		tile.name = node_name
		target_layer.add_child(tile)
	else:
		_move_visual_to_layer(tile, target_layer)
		_apply_sprite_texture_and_layout(tile, grid_pos, state_name, tex_path, Color.WHITE)

	_apply_visual_sorting(tile, grid_pos, state_name, tex_path)

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

func _apply_visual_sorting(tile: Sprite2D, grid_pos: Vector2i, state_name: String, tex_path: String) -> void:
	tile.z_as_relative = true
	tile.z_index = _get_visual_sort_key(grid_pos, state_name, tex_path)

func _get_visual_sort_key(grid_pos: Vector2i, state_name: String, tex_path: String) -> int:
	var row: int = grid_pos.y
	if _is_tall_visual(state_name, tex_path):
		row += 2
	elif _is_medium_visual(state_name, tex_path):
		row += 1
	return SORT_Z_BASE + row

func _is_tall_visual(state_name: String, tex_path: String) -> bool:
	var lower_tex_path: String = tex_path.to_lower()
	var lower_state_name: String = state_name.to_lower()
	if state_name == "BLUEPRINT":
		return false
	if "crop" in lower_tex_path or "sprout" in lower_tex_path or "ready" in lower_tex_path or "dirt" in lower_tex_path:
		return false
	if "blueprint_indicator" in lower_tex_path:
		return false
	return (
		"_house" in lower_tex_path
		or "warehouse" in lower_tex_path
		or "shop_building" in lower_tex_path
		or "bakery" in lower_tex_path
		or "mill" in lower_tex_path
		or "factory" in lower_tex_path
		or "coop" in lower_tex_path
		or "pen" in lower_tex_path
		or "cage" in lower_tex_path
		or lower_state_name in ["coop", "cow_pen", "bakery", "mill", "tomato_factory", "animal_feed_factory", "fish_cage", "storage", "farm_house", "gathering_house", "factory_house"]
	)

func _is_medium_visual(state_name: String, tex_path: String) -> bool:
	var lower_tex_path: String = tex_path.to_lower()
	var lower_state_name: String = state_name.to_lower()
	return (
		"tree" in lower_tex_path
		or "rock" in lower_tex_path
		or lower_state_name in ["tree", "rock"]
	)

func _create_sprite_node(grid_pos: Vector2i, state_name: String, texture_path: String, fallback_color: Color) -> Sprite2D:
	var sprite = Sprite2D.new()
	_apply_sprite_texture_and_layout(sprite, grid_pos, state_name, texture_path, fallback_color)
	return sprite

func _apply_sprite_texture_and_layout(sprite: Sprite2D, grid_pos: Vector2i, state_name: String, texture_path: String, fallback_color: Color) -> void:
	var visual_config: Dictionary = _get_visual_config(grid_pos, state_name, texture_path)
	var size_in_tiles: Vector2 = Vector2(visual_config.get("size_in_tiles", Vector2.ONE))
	var scale_multiplier: float = float(visual_config.get("scale_multiplier", 1.0))
	var y_offset_tiles: float = float(visual_config.get("y_offset_tiles", 0.0))
	var tex = _load_texture(texture_path)

	if tex == null:
		var fallback = GradientTexture2D.new()
		fallback.width = max(1, int(GameData.TILE_SIZE * size_in_tiles.x))
		fallback.height = max(1, int(GameData.TILE_SIZE * size_in_tiles.y))
		fallback.fill_to = Vector2(1, 1)
		var grad = Gradient.new()
		grad.set_color(0, fallback_color)
		grad.set_color(1, fallback_color.darkened(0.2))
		fallback.gradient = grad
		tex = fallback

	sprite.texture = tex
	var t_size: Vector2 = tex.get_size()
	sprite.scale = Vector2(
		(GameData.TILE_SIZE * size_in_tiles.x) / max(t_size.x, 1.0),
		(GameData.TILE_SIZE * size_in_tiles.y) / max(t_size.y, 1.0)
	) * scale_multiplier
	sprite.position = _grid_to_world_center(grid_pos) - Vector2(0.0, GameData.TILE_SIZE * y_offset_tiles)

func _get_visual_config(grid_pos: Vector2i, state_name: String, texture_path: String) -> Dictionary:
	var default_config: Dictionary = {
		"size_in_tiles": Vector2.ONE,
		"scale_multiplier": 1.0,
		"y_offset_tiles": 0.0,
	}
	var lower_texture_path: String = texture_path.to_lower()
	var lower_state_name: String = state_name.to_lower()

	if "crop" in lower_texture_path or "sprout" in lower_texture_path or "ready" in lower_texture_path:
		default_config["size_in_tiles"] = Vector2.ONE * 0.6
		return default_config

	var blueprint_def: BlueprintDefinition = _get_visual_blueprint_def(grid_pos)
	if blueprint_def != null:
		return {
			"size_in_tiles": _sanitize_visual_size(blueprint_def.visual_size_in_tiles),
			"scale_multiplier": blueprint_def.visual_scale if blueprint_def.visual_scale > 0.0 else 1.0,
			"y_offset_tiles": blueprint_def.visual_y_offset_tiles,
		}

	var processor_def: ProcessorDefinition = _get_visual_processor_def(grid_pos, state_name)
	if processor_def != null:
		return {
			"size_in_tiles": _sanitize_visual_size(processor_def.visual_size_in_tiles),
			"scale_multiplier": processor_def.visual_scale if processor_def.visual_scale > 0.0 else 1.0,
			"y_offset_tiles": processor_def.visual_y_offset_tiles,
		}

	if "_house" in lower_texture_path or "warehouse" in lower_texture_path or "shop_building" in lower_texture_path:
		return {
			"size_in_tiles": Vector2(2.2, 2.2),
			"scale_multiplier": 1.0,
			"y_offset_tiles": 0.28,
		}
	if "bakery" in lower_texture_path or "mill" in lower_texture_path or "factory" in lower_texture_path:
		return {
			"size_in_tiles": Vector2(1.9, 1.9),
			"scale_multiplier": 1.0,
			"y_offset_tiles": 0.2,
		}
	if "coop" in lower_texture_path or "pen" in lower_texture_path or "cage" in lower_texture_path:
		return {
			"size_in_tiles": Vector2(1.7, 1.7),
			"scale_multiplier": 1.0,
			"y_offset_tiles": 0.1,
		}
	if lower_state_name in ["coop", "cow_pen", "bakery", "mill", "tomato_factory", "animal_feed_factory", "fish_cage", "storage", "farm_house", "gathering_house", "factory_house"]:
		return {
			"size_in_tiles": Vector2(1.9, 1.9),
			"scale_multiplier": 1.0,
			"y_offset_tiles": 0.2,
		}
	return default_config

func _sanitize_visual_size(size_in_tiles: Vector2) -> Vector2:
	var width: float = size_in_tiles.x if size_in_tiles.x > 0.0 else 1.0
	var height: float = size_in_tiles.y if size_in_tiles.y > 0.0 else 1.0
	return Vector2(width, height)

func _get_visual_blueprint_def(grid_pos: Vector2i) -> BlueprintDefinition:
	if _farm_manager == null:
		return null
	var blueprint_id: String = _farm_manager.get_blueprint_id(grid_pos)
	if blueprint_id != "":
		return GameData.get_blueprint_def(blueprint_id)
	var tile_type: String = _farm_manager.get_tile_type(grid_pos)
	if tile_type != "":
		return GameData.get_blueprint_def(tile_type)
	return null

func _get_visual_processor_def(grid_pos: Vector2i, state_name: String) -> ProcessorDefinition:
	if _farm_manager == null:
		return null
	var processor_type: String = _farm_manager.get_processor_type(grid_pos)
	if processor_type != "":
		return GameData.get_processor_def(processor_type)
	if state_name != "":
		return GameData.get_processor_def(state_name)
	return null

func _load_texture(texture_path: String) -> Texture2D:
	if texture_path == "":
		return null
	if _texture_cache.has(texture_path):
		return _texture_cache[texture_path]
	var tex := ResourceLoader.load(texture_path) as Texture2D
	if tex != null:
		_texture_cache[texture_path] = tex
	return tex

func _spawn_sprite(parent: Node2D, grid_pos: Vector2i, texture_path: String, fallback_color: Color) -> void:
	var sprite = _create_sprite_node(grid_pos, "", texture_path, fallback_color)
	_apply_visual_sorting(sprite, grid_pos, "", texture_path)
	parent.add_child(sprite)
