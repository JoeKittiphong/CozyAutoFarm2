class_name GameData
extends RefCounted

const STORAGE_POS := Vector2i(-2, -1)
const PROCESSING_STORAGE_POS := Vector2i(2, -1)
const SHOP_POS := Vector2i(-6, -1)
const MAX_UPGRADE_LEVEL := 5

const SHOP_CATEGORY_SHOP := "SHOP"
const SHOP_CATEGORY_WORKER_HOUSE := "WORKER_HOUSE"

const ITEM_WHEAT := "WHEAT"
const ITEM_TOMATO := "TOMATO"
const ITEM_POTATO := "POTATO"
const ITEM_FLOUR := "FLOUR"
const ITEM_ANIMAL_FEED := "ANIMAL_FEED"
const ITEM_FISH := "FISH"
const ITEM_EGG := "EGG"
const ITEM_MILK := "MILK"
const ITEM_CAKE := "CAKE"
const ITEM_TOMATO_SAUCE := "TOMATO_SAUCE"

const BLUEPRINT_WHEAT := "WHEAT"
const BLUEPRINT_TOMATO := "TOMATO"
const BLUEPRINT_POTATO := "POTATO"
const BLUEPRINT_COOP := "COOP"
const BLUEPRINT_COW_PEN := "COW_PEN"
const BLUEPRINT_BAKERY := "BAKERY"
const BLUEPRINT_MILL := "MILL"
const BLUEPRINT_TOMATO_FACTORY := "TOMATO_FACTORY"
const BLUEPRINT_FISH_CAGE := "FISH_CAGE"
const BLUEPRINT_ANIMAL_FEED_FACTORY := "ANIMAL_FEED_FACTORY"

const PROCESSOR_BAKERY := "BAKERY"
const PROCESSOR_MILL := "MILL"
const PROCESSOR_TOMATO_FACTORY := "TOMATO_FACTORY"
const PROCESSOR_FISH_CAGE := "FISH_CAGE"
const PROCESSOR_ANIMAL_FEED_FACTORY := "ANIMAL_FEED_FACTORY"

const ANIMAL_CHICKEN := "CHICKEN"
const ANIMAL_COW := "COW"
const GROUP_CHICKENS := "chickens"
const GROUP_COWS := "cows"

const JOB_TILL := "TILL"
const JOB_PLANT := "PLANT"
const JOB_WATER := "WATER"
const JOB_HARVEST := "HARVEST"
const JOB_DELIVER := "DELIVER"
const JOB_FEED_ANIMAL := "FEED_ANIMAL"
const JOB_COLLECT_ANIMAL_PRODUCT := "COLLECT_ANIMAL_PRODUCT"
const JOB_FETCH_ANIMAL := "FETCH_ANIMAL"
const JOB_PROCESSOR_DELIVER := "PROCESSOR_DELIVER"
const JOB_PROCESSOR_COLLECT := "PROCESSOR_COLLECT"

const WORK_MODE_AUTO := "AUTO"
const WORK_MODE_ASSIGNED := "ASSIGNED"
const WORKER_ROLE_CROP_CARE := "CROP_CARE"
const WORKER_ROLE_PROCESSOR_DELIVERY := "PROCESSOR_DELIVERY"
const WORKER_ROLE_PROCESSOR_COLLECT := "PROCESSOR_COLLECT"
const WORKER_ROLE_ANIMAL_CARE := "ANIMAL_CARE"
const WORKER_ROLE_GENERAL_DELIVERY := "GENERAL_DELIVERY"

const STATE_WAITING_DELIVERY := "WAITING_DELIVERY"
const STATE_HUNGRY := "HUNGRY"
const STATE_WANDERING_FED := "WANDERING_FED"
const STATE_EGG_READY := "EGG_READY"
const STATE_MILK_READY := "MILK_READY"

const ITEMS_DIR := "res://data/items"
const BLUEPRINTS_DIR := "res://data/blueprints"
const PROCESSORS_DIR := "res://data/processors"
const ANIMALS_DIR := "res://data/animals"

const PREFERRED_ITEM_ORDER := [
	ITEM_WHEAT,
	ITEM_TOMATO,
	ITEM_POTATO,
	ITEM_FLOUR,
	ITEM_ANIMAL_FEED,
	ITEM_FISH,
	ITEM_EGG,
	ITEM_MILK,
	ITEM_CAKE,
	ITEM_TOMATO_SAUCE,
]
const PREFERRED_BLUEPRINT_ORDER := [
	BLUEPRINT_WHEAT,
	BLUEPRINT_COOP,
	BLUEPRINT_COW_PEN,
	BLUEPRINT_BAKERY,
	BLUEPRINT_TOMATO,
	BLUEPRINT_POTATO,
	BLUEPRINT_MILL,
	BLUEPRINT_TOMATO_FACTORY,
	BLUEPRINT_ANIMAL_FEED_FACTORY,
	BLUEPRINT_FISH_CAGE,
]
const PREFERRED_ANIMAL_ORDER := [ANIMAL_CHICKEN, ANIMAL_COW]
const PREFERRED_PROCESSOR_ORDER := [PROCESSOR_MILL, PROCESSOR_BAKERY, PROCESSOR_TOMATO_FACTORY, PROCESSOR_ANIMAL_FEED_FACTORY, PROCESSOR_FISH_CAGE]

const CROP_VISUALS := {
	"WHEAT": {"sprout": "res://assets/sprites/wheat_sprout.png", "ready": "res://assets/sprites/wheat_ready.png"},
	"TOMATO": {"sprout": "res://assets/sprites/tomato_sprout.png", "ready": "res://assets/sprites/tomato_ready.png"},
	"POTATO": {"sprout": "res://assets/sprites/potato_sprout.png", "ready": "res://assets/sprites/potato_ready.png"},
}

static var _item_defs_by_id: Dictionary = {}
static var _processor_defs_by_id: Dictionary = {}
static var _blueprint_defs_by_id: Dictionary = {}
static var _animal_defs_by_id: Dictionary = {}
static var _item_order: Array[String] = []
static var _sellable_item_order: Array[String] = []
static var _blueprint_order: Array[String] = []
static var _shop_animal_order: Array[String] = []

static func _ensure_resource_maps() -> void:
	if not _item_defs_by_id.is_empty():
		return

	for item_def in _load_resources_from_folder(ITEMS_DIR):
		if item_def is ItemDefinition and item_def.item_id != "":
			_item_defs_by_id[item_def.item_id] = item_def

	for blueprint_def in _load_resources_from_folder(BLUEPRINTS_DIR):
		if blueprint_def is BlueprintDefinition and blueprint_def.blueprint_id != "":
			_blueprint_defs_by_id[blueprint_def.blueprint_id] = blueprint_def

	for processor_def in _load_resources_from_folder(PROCESSORS_DIR):
		if processor_def is ProcessorDefinition and processor_def.processor_type != "":
			_processor_defs_by_id[processor_def.processor_type] = processor_def

	for animal_def in _load_resources_from_folder(ANIMALS_DIR):
		if animal_def is AnimalDefinition and animal_def.animal_id != "":
			_animal_defs_by_id[animal_def.animal_id] = animal_def

	_item_order = _sort_ids_with_preferred(_item_defs_by_id.keys(), PREFERRED_ITEM_ORDER)
	_sellable_item_order = _item_order.duplicate()
	_blueprint_order = _sort_ids_with_preferred(_blueprint_defs_by_id.keys(), PREFERRED_BLUEPRINT_ORDER)
	_shop_animal_order = _sort_ids_with_preferred(_animal_defs_by_id.keys(), PREFERRED_ANIMAL_ORDER)

static func _load_resources_from_folder(folder_path: String) -> Array:
	var results: Array = []
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return results

	var file_names: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			file_names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	file_names.sort()

	for sorted_file_name in file_names:
		var resource = load(folder_path.path_join(sorted_file_name))
		if resource != null:
			results.append(resource)
	return results

static func _sort_ids_with_preferred(ids: Array, preferred_order: Array) -> Array[String]:
	var sorted_ids: Array[String] = []
	var remaining: Array[String] = []
	for raw_id in ids:
		remaining.append(String(raw_id))
	remaining.sort()

	for preferred_id in preferred_order:
		var preferred: String = String(preferred_id)
		if preferred in remaining:
			sorted_ids.append(preferred)
			remaining.erase(preferred)

	for leftover_id in remaining:
		sorted_ids.append(leftover_id)
	return sorted_ids

static func _get_level_texture(level_textures: Array[String], level: int, fallback: String = "") -> String:
	if level_textures.is_empty():
		return fallback
	var idx: int = clamp(level - 1, 0, level_textures.size() - 1)
	var path: String = String(level_textures[idx])
	return path if path != "" else fallback

static func get_item_order() -> Array[String]:
	_ensure_resource_maps()
	return _item_order.duplicate()

static func get_sellable_item_order() -> Array[String]:
	_ensure_resource_maps()
	return _sellable_item_order.duplicate()

static func get_blueprint_order() -> Array[String]:
	_ensure_resource_maps()
	return _blueprint_order.duplicate()

static func get_blueprint_order_by_shop_category(shop_category: String) -> Array[String]:
	_ensure_resource_maps()
	if shop_category == "":
		return get_blueprint_order()
	var result: Array[String] = []
	for blueprint_id in _blueprint_order:
		var blueprint_def: BlueprintDefinition = get_blueprint_def(blueprint_id)
		if blueprint_def == null:
			continue
		var current_category: String = blueprint_def.shop_category if blueprint_def.shop_category != "" else SHOP_CATEGORY_SHOP
		if current_category == shop_category:
			result.append(blueprint_id)
	return result

static func get_shop_animal_order() -> Array[String]:
	_ensure_resource_maps()
	return _shop_animal_order.duplicate()

static func get_item_def(item_type: String) -> ItemDefinition:
	_ensure_resource_maps()
	return _item_defs_by_id.get(item_type, null)

static func get_blueprint_def(blueprint_type: String) -> BlueprintDefinition:
	_ensure_resource_maps()
	return _blueprint_defs_by_id.get(blueprint_type, null)

static func get_blueprint_level_texture(blueprint_type: String, level: int) -> String:
	var blueprint_def: BlueprintDefinition = get_blueprint_def(blueprint_type)
	if blueprint_def == null:
		return ""
	return _get_level_texture(blueprint_def.level_textures, level, blueprint_def.texture_path)

static func get_crop_visual(crop_type: String, stage: String, level: int = 1) -> String:
	var blueprint_def: BlueprintDefinition = get_blueprint_def(crop_type)
	if blueprint_def != null:
		if stage == "sprout":
			var sprout_fallback: String = String(CROP_VISUALS.get(crop_type, {}).get("sprout", ""))
			return _get_level_texture(blueprint_def.level_sprout_textures, level, sprout_fallback)
		if stage == "ready":
			var ready_fallback: String = String(CROP_VISUALS.get(crop_type, {}).get("ready", ""))
			return _get_level_texture(blueprint_def.level_ready_textures, level, ready_fallback)
	var crop_visuals: Dictionary = CROP_VISUALS.get(crop_type, CROP_VISUALS["WHEAT"])
	return String(crop_visuals.get(stage, ""))

static func get_processor_def(processor_type: String) -> ProcessorDefinition:
	_ensure_resource_maps()
	return _processor_defs_by_id.get(processor_type, null)

static func get_processor_level_texture(processor_type: String, level: int) -> String:
	var processor_def: ProcessorDefinition = get_processor_def(processor_type)
	if processor_def == null:
		return ""
	var idle_fallback: String = processor_def.idle_texture_path if processor_def.idle_texture_path != "" else processor_def.ready_texture_path
	return _get_level_texture(processor_def.level_textures, level, idle_fallback)

static func get_processor_ready_texture(processor_type: String, level: int) -> String:
	var processor_def: ProcessorDefinition = get_processor_def(processor_type)
	if processor_def == null:
		return ""
	return _get_level_texture(processor_def.ready_level_textures, level, processor_def.ready_texture_path)

static func get_animal_level_texture(animal_type: String, level: int) -> String:
	var animal_def: AnimalDefinition = get_animal_def(animal_type)
	if animal_def == null:
		return ""
	return _get_level_texture(animal_def.level_textures, level, animal_def.icon_path)

static func get_animal_def(animal_type: String) -> AnimalDefinition:
	_ensure_resource_maps()
	return _animal_defs_by_id.get(animal_type, null)

static func get_animal_defs_for_pen(pen_blueprint_type: String) -> Array:
	_ensure_resource_maps()
	var result: Array = []
	for animal_def in _animal_defs_by_id.values():
		if animal_def.pen_blueprint_type == pen_blueprint_type:
			result.append(animal_def)
	return result

static func get_worker_mode_options() -> Array[Dictionary]:
	return [
		{"id": WORK_MODE_AUTO, "label": "Auto"},
		{"id": WORK_MODE_ASSIGNED, "label": "Assigned"},
	]

static func get_worker_role_options() -> Array[Dictionary]:
	return [
		{"id": WORKER_ROLE_CROP_CARE, "label": "Crop Care"},
		{"id": WORKER_ROLE_PROCESSOR_DELIVERY, "label": "Processor Delivery"},
		{"id": WORKER_ROLE_PROCESSOR_COLLECT, "label": "Processor Collect"},
		{"id": WORKER_ROLE_ANIMAL_CARE, "label": "Animal Care"},
		{"id": WORKER_ROLE_GENERAL_DELIVERY, "label": "General Delivery"},
	]

static func get_worker_role_label(role_id: String) -> String:
	for option in get_worker_role_options():
		if String(option.get("id", "")) == role_id:
			return String(option.get("label", role_id))
	return role_id

static func get_worker_target_options(role_id: String) -> Array[Dictionary]:
	_ensure_resource_maps()
	var options: Array[Dictionary] = [{"id": "", "label": "Any"}]
	match role_id:
		WORKER_ROLE_CROP_CARE:
			var crop_ids: Array[String] = []
			for blueprint_id in get_blueprint_order():
				var blueprint_def: BlueprintDefinition = get_blueprint_def(blueprint_id)
				if blueprint_def != null and blueprint_def.placement_type == "CROP" and blueprint_def.crop_type != "" and not crop_ids.has(blueprint_def.crop_type):
					crop_ids.append(blueprint_def.crop_type)
			crop_ids.sort()
			for crop_id in crop_ids:
				var item_def: ItemDefinition = get_item_def(crop_id)
				options.append({"id": crop_id, "label": item_def.label if item_def != null else crop_id})
		WORKER_ROLE_PROCESSOR_DELIVERY, WORKER_ROLE_PROCESSOR_COLLECT:
			for processor_id in _sort_ids_with_preferred(_processor_defs_by_id.keys(), PREFERRED_PROCESSOR_ORDER):
				var processor_def: ProcessorDefinition = get_processor_def(processor_id)
				options.append({"id": processor_id, "label": processor_def.label if processor_def != null else processor_id})
		WORKER_ROLE_ANIMAL_CARE:
			for animal_id in get_shop_animal_order():
				var animal_def: AnimalDefinition = get_animal_def(animal_id)
				options.append({"id": animal_id, "label": animal_def.label if animal_def != null else animal_id})
		_:
			pass
	return options

static func get_worker_target_label(role_id: String, target_id: String) -> String:
	if target_id == "":
		return "Any"

	match role_id:
		WORKER_ROLE_CROP_CARE:
			var item_def: ItemDefinition = get_item_def(target_id)
			return item_def.label if item_def != null else target_id
		WORKER_ROLE_PROCESSOR_DELIVERY, WORKER_ROLE_PROCESSOR_COLLECT:
			var processor_def: ProcessorDefinition = get_processor_def(target_id)
			return processor_def.label if processor_def != null else target_id
		WORKER_ROLE_ANIMAL_CARE:
			var animal_def: AnimalDefinition = get_animal_def(target_id)
			return animal_def.label if animal_def != null else target_id
		_:
			return target_id

static func get_blueprint_price(blueprint_type: String, bought_count: int) -> int:
	var blueprint_def: BlueprintDefinition = get_blueprint_def(blueprint_type)
	if blueprint_def == null:
		return 0
	return int(floor(blueprint_def.base_price * pow(blueprint_def.growth, bought_count)))

static func get_worker_price(count_workers_bought: int) -> int:
	return 5 + (5 * count_workers_bought)

static func get_max_workers(house_level: int) -> int:
	return house_level * 2

static func get_house_upgrade_price(house_level: int) -> int:
	return int(floor(100.0 * pow(2.0, house_level - 1)))

static func get_tile_upgrade_price(is_processor: bool, level: int) -> int:
	var base := 25
	if is_processor:
		base = 50
	return int(floor(base * pow(2.0, level - 1)))
