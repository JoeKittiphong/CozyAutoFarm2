extends Node2D
class_name FarmWorker

@export var move_speed: float = 300.0
const TILE_SIZE = 128

var current_path: Array[Vector2i] = []
var current_job: Dictionary = {}
var is_working: bool = false
var carried_wheat: int = 0
var carried_tomato: int = 0
var carried_potato: int = 0
var carried_flour: int = 0
var carried_egg: int = 0
var carried_milk: int = 0
var carried_cake: int = 0
var carried_animal: Node2D = null
const MAX_CARRY: int = 3
var _work_tween: Tween

@onready var sprite: Sprite2D = Sprite2D.new()

func _ready() -> void:
	var tex = ResourceLoader.load("res://assets/sprites/worker.png")
			
	if tex == null:
		var fallback = GradientTexture2D.new()
		fallback.width = 80
		fallback.height = 80
		fallback.fill_to = Vector2(1,1)
		var grad = Gradient.new()
		grad.set_color(0, Color.GOLD)
		grad.set_color(1, Color.ORANGE)
		fallback.gradient = grad
		tex = fallback
		sprite.texture = tex
	else:
		sprite.texture = tex
		var t_size = tex.get_size()
		sprite.scale = Vector2(TILE_SIZE / t_size.x, TILE_SIZE / t_size.y) * 0.9 # Slightly smaller than tile
		
	sprite.position = Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)
	add_child(sprite)

func _process(delta: float) -> void:
	if is_working:
		return
		
	if current_path.is_empty():
		if current_job.is_empty():
			var j_manager = get_node("/root/JobManager")
			var job = j_manager.get_next_job()
			if not job.is_empty():
				current_job = job
				var grid_pos = _get_current_grid_pos()
				
				var complex_jobs = ["FEED_CHICKEN", "COLLECT_EGG", "FETCH_ANIMAL", "FEED_COW", "COLLECT_MILK", 
									"BAKERY_DELIVER_FLOUR", "BAKERY_DELIVER_EGG", "BAKERY_DELIVER_MILK", "COLLECT_CAKE",
									"MILL_DELIVER_WHEAT", "COLLECT_FLOUR"]
				if current_job.type in complex_jobs:
					_start_work() # Delegate pathing entirely to start_work for complex jobs
				else:
					current_path = GridManager.get_path_cells(grid_pos, current_job.target_pos)
					if current_path.is_empty():
						if grid_pos == current_job.target_pos:
							if current_job.type == "DELIVER":
								_complete_delivery()
							else:
								_start_work()
						else:
							current_job.clear()
			else:
				if carried_wheat > 0:
					_start_delivery()
		else:
			if current_job.type == "DELIVER":
				if current_path.is_empty():
					_complete_delivery()
			else:
				if current_path.is_empty():
					_start_work()
	else:
		var target_grid_pos = current_path[0]
		var target_world_pos = Vector2(target_grid_pos) * TILE_SIZE
		
		var dir = (target_world_pos - position).normalized()
		var dist = position.distance_to(target_world_pos)
		
		var move_amount = move_speed * delta
		if move_amount >= dist:
			position = target_world_pos
			current_path.pop_front()
		else:
			position += dir * move_amount

func _get_current_grid_pos() -> Vector2i:
	return Vector2i(round(position.x / TILE_SIZE), round(position.y / TILE_SIZE))

func _start_work() -> void:
	is_working = true
	
	if _work_tween and _work_tween.is_valid():
		_work_tween.kill()
	_work_tween = create_tween().set_loops(3)
	_work_tween.tween_property(sprite, "position:y", TILE_SIZE/2.0 - 20, 0.15)
	_work_tween.tween_property(sprite, "position:y", TILE_SIZE/2.0, 0.15)
	
	await get_tree().create_timer(1.0).timeout
	
	if current_job.type == "TILL":
		get_node("/root/FarmManager").complete_till(current_job.target_pos)
	elif current_job.type == "PLANT":
		get_node("/root/FarmManager").complete_plant(current_job.target_pos)
	elif current_job.type == "WATER":
		get_node("/root/FarmManager").complete_water(current_job.target_pos)
	elif current_job.type == "HARVEST":
		var f_manager = get_node("/root/FarmManager")
		var crop_type = f_manager.get_tile_type(current_job.target_pos)
		f_manager.complete_harvest(current_job.target_pos)
		
		if crop_type == "TOMATO": carried_tomato += 1
		elif crop_type == "POTATO": carried_potato += 1
		else: carried_wheat += 1
		
		_update_carried_visual()
		current_job.clear()
		is_working = false
		
		var total_carried = carried_wheat + carried_tomato + carried_potato
		if total_carried >= MAX_CARRY:
			_start_delivery()
		return

	elif current_job.type == "FEED_CHICKEN":
		if carried_flour < 1:
			var grid_pos = _get_current_grid_pos()
			if grid_pos != Vector2i(2, -1):
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, Vector2i(2, -1))
				is_working = false
				return
			else:
				var inv = get_node("/root/InventoryManager")
				if inv.flour_stock > 0:
					inv.flour_stock -= 1
					inv.resources_updated.emit()
					carried_flour += 1
					_update_carried_visual()
					current_path = get_node("/root/GridManager").get_path_cells(grid_pos, current_job.target_pos)
				else:
					get_node("/root/JobManager").add_job("FEED_CHICKEN", current_job.target_pos)
					current_job.clear()
				is_working = false
				return
		else:
			for c in get_tree().get_nodes_in_group("chickens"):
				if c.home_pos == current_job.target_pos:
					c.feed()
					carried_flour -= 1
					_update_carried_visual()
					break
			current_job.clear()
			is_working = false
			return

	elif current_job.type == "MILL_DELIVER_WHEAT":
		if carried_wheat < 3:
			var grid_pos = _get_current_grid_pos()
			if grid_pos != Vector2i(-2, -1): # Wheat storage area
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, Vector2i(-2, -1))
				is_working = false
				return
			else:
				var inv = get_node("/root/InventoryManager")
				if inv.wheat_stock >= 3:
					inv.wheat_stock -= 3
					inv.resources_updated.emit()
					carried_wheat = 3
					_update_carried_visual()
					current_path = get_node("/root/GridManager").get_path_cells(grid_pos, current_job.target_pos)
				else:
					get_node("/root/JobManager").add_job("MILL_DELIVER_WHEAT", current_job.target_pos)
					current_job.clear()
				is_working = false
				return
		else:
			get_node("/root/FarmManager").deliver_wheat_to_mill(current_job.target_pos)
			carried_wheat = 0
			_update_carried_visual()
			current_job.clear()
			is_working = false
			return

	elif current_job.type == "COLLECT_FLOUR":
		if carried_flour < 1:
			var grid_pos = _get_current_grid_pos()
			if grid_pos != current_job.target_pos:
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, current_job.target_pos)
				is_working = false
				return
			else:
				get_node("/root/FarmManager").collect_flour_from_mill(current_job.target_pos)
				carried_flour += 1
				_update_carried_visual()
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, Vector2i(2, -1)) # Storage area
				is_working = false
				return
		else:
			var inv = get_node("/root/InventoryManager")
			inv.flour_stock += 1
			inv.resources_updated.emit()
			carried_flour = 0
			_update_carried_visual()
			current_job.clear()
			is_working = false
			return

	elif current_job.type == "COLLECT_EGG":
		if carried_egg < 1:
			var grid_pos = _get_current_grid_pos()
			if grid_pos != current_job.target_pos:
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, current_job.target_pos)
				is_working = false
				return
			else:
				for c in get_tree().get_nodes_in_group("chickens"):
					if c.home_pos == current_job.target_pos:
						c.collect_egg()
						carried_egg += 1
						_update_carried_visual()
						break
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, Vector2i(-2, -1))
				is_working = false
				return
		else:
			var inv = get_node("/root/InventoryManager")
			inv.add_egg(1)
			carried_egg -= 1
			_update_carried_visual()
			current_job.clear()
			is_working = false
			return

	elif current_job.type == "FEED_COW":
		if carried_wheat < 3:
			var grid_pos = _get_current_grid_pos()
			if grid_pos != Vector2i(-2, -1):
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, Vector2i(-2, -1))
				is_working = false
				return
			else:
				var inv = get_node("/root/InventoryManager")
				if inv.wheat_stock >= 3:
					inv.wheat_stock -= 3
					inv.resources_updated.emit()
					carried_wheat = 3
					_update_carried_visual()
					current_path = get_node("/root/GridManager").get_path_cells(grid_pos, current_job.target_pos)
				else:
					get_node("/root/JobManager").add_job("FEED_COW", current_job.target_pos)
					current_job.clear()
				is_working = false
				return
		else:
			for c in get_tree().get_nodes_in_group("cows"):
				if c.home_pos == current_job.target_pos:
					c.feed()
					carried_wheat = 0
					_update_carried_visual()
					break
			current_job.clear()
			is_working = false
			return

	elif current_job.type == "COLLECT_MILK":
		if carried_milk < 1:
			var grid_pos = _get_current_grid_pos()
			if grid_pos != current_job.target_pos:
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, current_job.target_pos)
				is_working = false
				return
			else:
				for c in get_tree().get_nodes_in_group("cows"):
					if c.home_pos == current_job.target_pos:
						c.collect_milk()
						carried_milk += 1
						_update_carried_visual()
						break
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, Vector2i(-2, -1))
				is_working = false
				return
		else:
			var inv = get_node("/root/InventoryManager")
			inv.add_milk(1)
			carried_milk -= 1
			_update_carried_visual()
			current_job.clear()
			is_working = false
			return

	elif current_job.type == "FETCH_ANIMAL":
		if carried_animal == null:
			var grid_pos = _get_current_grid_pos()
			if grid_pos != Vector2i(-6, -1):
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, Vector2i(-6, -1))
				is_working = false
				return
			else:
				carried_animal = current_job.animal_node
				carried_animal.visible = false
				_update_carried_visual()
				
				var f_manager = get_node("/root/FarmManager")
				var dest = Vector2i.ZERO
				var found = false
				var target_state = f_manager.TileState.COOP if current_job.animal_type == "CHICKEN" else f_manager.TileState.COW_PEN
				for cell in f_manager._farm_data.keys():
					if f_manager._farm_data[cell] == target_state:
						var has_an = false
						var gn = "chickens" if current_job.animal_type == "CHICKEN" else "cows"
						for a in get_tree().get_nodes_in_group(gn):
							if a.home_pos == cell:
								has_an = true
								break
						if not has_an:
							dest = cell
							found = true
							break
				if found:
					current_path = get_node("/root/GridManager").get_path_cells(grid_pos, dest)
					current_job.target_pos = dest
				else:
					carried_animal.visible = true
					carried_animal = null
					current_job.clear()
				is_working = false
				return
		else:
			carried_animal.visible = true
			carried_animal.setup(current_job.target_pos)
			carried_animal = null
			_update_carried_visual()
			current_job.clear()
			is_working = false
			return
		
	elif "BAKERY_DELIVER" in current_job.type:
		var res_type = ""
		var silo_pos = Vector2i(-2, -1)
		var inv_var = ""
		
		if "FLOUR" in current_job.type:
			res_type = "FLOUR"
			silo_pos = Vector2i(2, -1)
			inv_var = "flour_stock"
		elif "EGG" in current_job.type:
			res_type = "EGG"
			inv_var = "egg_stock"
		elif "MILK" in current_job.type:
			res_type = "MILK"
			inv_var = "milk_stock"
			
		var count_var = "carried_" + res_type.to_lower()
		if get(count_var) < 1:
			var grid_pos = _get_current_grid_pos()
			if grid_pos != silo_pos:
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, silo_pos)
				is_working = false
				return
			else:
				var inv = get_node("/root/InventoryManager")
				if inv.get(inv_var) > 0:
					inv.set(inv_var, inv.get(inv_var) - 1)
					inv.resources_updated.emit()
					set(count_var, 1)
					_update_carried_visual()
					current_path = get_node("/root/GridManager").get_path_cells(grid_pos, current_job.target_pos)
				else:
					get_node("/root/JobManager").add_job(current_job.type, current_job.target_pos)
					current_job.clear()
				is_working = false
				return
		else:
			get_node("/root/FarmManager").deliver_to_bakery(current_job.target_pos, res_type)
			set(count_var, 0)
			_update_carried_visual()
			current_job.clear()
			is_working = false
			return

	elif current_job.type == "COLLECT_CAKE":
		if carried_cake < 1:
			var grid_pos = _get_current_grid_pos()
			if grid_pos != current_job.target_pos:
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, current_job.target_pos)
				is_working = false
				return
			else:
				get_node("/root/FarmManager").collect_cake_from_bakery(current_job.target_pos)
				carried_cake += 1
				_update_carried_visual()
				current_path = get_node("/root/GridManager").get_path_cells(grid_pos, Vector2i(2, -1)) # Deliver to shop area
				is_working = false
				return
		else:
			var inv = get_node("/root/InventoryManager")
			inv.add_cake(1)
			carried_cake = 0
			_update_carried_visual()
			current_job.clear()
			is_working = false
			return
		
	current_job.clear()
	is_working = false

func _update_carried_visual() -> void:
	if has_node("CarriedItem"):
		get_node("CarriedItem").queue_free()
		
	var tex_path = ""
	var count = 0
	if carried_wheat > 0:
		tex_path = "res://assets/sprites/wheat_item.png"
		count = carried_wheat
	elif carried_tomato > 0:
		tex_path = "res://assets/sprites/tomato_item.png"
		count = carried_tomato
	elif carried_potato > 0:
		tex_path = "res://assets/sprites/potato_item.png"
		count = carried_potato
	elif carried_flour > 0:
		tex_path = "res://assets/sprites/flour_bag.png"
		count = carried_flour
	elif carried_egg > 0:
		tex_path = "res://assets/sprites/egg_item.png"
		count = carried_egg
	elif carried_milk > 0:
		tex_path = "res://assets/sprites/milk_bucket.png"
		count = carried_milk
	elif carried_cake > 0:
		tex_path = "res://assets/sprites/cake_final.png"
		count = carried_cake
	elif carried_animal != null:
		if current_job.has("animal_type") and current_job.animal_type == "CHICKEN":
			tex_path = "res://assets/sprites/chicken.png"
		else:
			tex_path = "res://assets/sprites/cow.png"
		count = 1
		
	if tex_path == "":
		return
		
	var item_sprite = Sprite2D.new()
	var tex = ResourceLoader.load(tex_path)
	if tex:
		item_sprite.texture = tex
		var t_size = tex.get_size()
		item_sprite.scale = Vector2(TILE_SIZE / t_size.x, TILE_SIZE / t_size.y) * 0.5
	item_sprite.name = "CarriedItem"
	add_child(item_sprite)
	item_sprite.position = Vector2(TILE_SIZE/2.0, -10.0 - (count * 8))

func _start_delivery() -> void:
	current_job = {"type": "DELIVER", "target_pos": Vector2i(2, -1)}
	var grid_pos = _get_current_grid_pos()
	current_path = get_node("/root/GridManager").get_path_cells(grid_pos, current_job.target_pos)
	is_working = false

func _complete_delivery() -> void:
	is_working = true
	await get_tree().create_timer(0.5).timeout
	if has_node("CarriedItem"):
		get_node("CarriedItem").queue_free()
		
	var inv = get_node_or_null("/root/InventoryManager")
	if inv:
		if carried_wheat > 0: inv.add_wheat(carried_wheat)
		if carried_tomato > 0: 
			inv.tomato_stock += carried_tomato
			inv.resources_updated.emit()
		if carried_potato > 0:
			inv.potato_stock += carried_potato
			inv.resources_updated.emit()
			
	carried_wheat = 0
	carried_tomato = 0
	carried_potato = 0
	
	current_job.clear()
	is_working = false
