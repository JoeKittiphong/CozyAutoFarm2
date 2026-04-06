class_name GameData
extends RefCounted


const STORAGE_POS := Vector2i(-2, -1)
const PROCESSING_STORAGE_POS := Vector2i(2, -1)
const SHOP_POS := Vector2i(-6, -1)
const MAX_UPGRADE_LEVEL := 5

const ITEM_WHEAT := "WHEAT"
const ITEM_TOMATO := "TOMATO"
const ITEM_POTATO := "POTATO"
const ITEM_FLOUR := "FLOUR"
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

const PROCESSOR_BAKERY := "BAKERY"
const PROCESSOR_MILL := "MILL"
const PROCESSOR_TOMATO_FACTORY := "TOMATO_FACTORY"

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
]
const PREFERRED_ANIMAL_ORDER := [ANIMAL_CHICKEN, ANIMAL_COW]

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

static func get_item_order() -> Array[String]:
	_ensure_resource_maps()
	return _item_order.duplicate()

static func get_sellable_item_order() -> Array[String]:
	_ensure_resource_maps()
	return _sellable_item_order.duplicate()

static func get_blueprint_order() -> Array[String]:
	_ensure_resource_maps()
	return _blueprint_order.duplicate()

static func get_shop_animal_order() -> Array[String]:
	_ensure_resource_maps()
	return _shop_animal_order.duplicate()

static func get_item_def(item_type: String) -> ItemDefinition:
	_ensure_resource_maps()
	return _item_defs_by_id.get(item_type, null)

static func get_blueprint_def(blueprint_type: String) -> BlueprintDefinition:
	_ensure_resource_maps()
	return _blueprint_defs_by_id.get(blueprint_type, null)

static func get_crop_visual(crop_type: String, stage: String) -> String:
	var crop_visuals: Dictionary = CROP_VISUALS.get(crop_type, CROP_VISUALS["WHEAT"])
	return String(crop_visuals.get(stage, ""))

static func get_processor_def(processor_type: String) -> ProcessorDefinition:
	_ensure_resource_maps()
	return _processor_defs_by_id.get(processor_type, null)

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
