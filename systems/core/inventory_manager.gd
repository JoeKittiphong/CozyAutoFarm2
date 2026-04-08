extends Node
class_name InventoryClass

signal resources_updated
signal targets_updated

const ANIMAL_FEED_POINTS_PER_BAG := 40

var money: int = 100
var mill_count: int = 0
var house_level: int = 1
var mill_paused: bool = false
var animal_feed_points: int = 0

var item_stock: Dictionary = {}
var blueprint_stock: Dictionary = {}
var blueprint_purchase_counts: Dictionary = {}
var count_workers_bought: int = 0
var worker_counts_by_domain: Dictionary = {}
var house_levels_by_domain: Dictionary = {}
var item_targets: Dictionary = {}

const MILL_TIME: float = 5.0

func _ready() -> void:
	for item_type in GameData.get_item_order():
		item_stock[item_type] = 0
		item_targets[item_type] = 0

	for blueprint_type in GameData.get_blueprint_order():
		blueprint_stock[blueprint_type] = 0
		blueprint_purchase_counts[blueprint_type] = 0

	for domain_option in GameData.get_worker_domain_options():
		var domain_id: String = String(domain_option.get("id", ""))
		worker_counts_by_domain[domain_id] = 0
		house_levels_by_domain[domain_id] = 1

func _process(_delta: float) -> void:
	pass

func get_item_stock(item_type: String) -> int:
	return int(item_stock.get(item_type, 0))

func get_item_target(item_type: String) -> int:
	return int(item_targets.get(item_type, 0))

func set_item_target(item_type: String, amount: int) -> void:
	item_targets[item_type] = max(amount, 0)
	targets_updated.emit()

func get_item_shortage(item_type: String) -> int:
	return max(get_item_target(item_type) - get_item_stock(item_type), 0)

func is_item_below_target(item_type: String) -> bool:
	return get_item_shortage(item_type) > 0

func add_item(item_type: String, amount: int) -> void:
	item_stock[item_type] = get_item_stock(item_type) + amount
	resources_updated.emit()

func spend_item(item_type: String, amount: int) -> bool:
	var current := get_item_stock(item_type)
	if current < amount:
		return false

	item_stock[item_type] = current - amount
	resources_updated.emit()
	return true

func has_resource_costs(costs: Array) -> bool:
	for cost in costs:
		if cost == null or cost.item_def == null:
			continue
		if get_item_stock(cost.item_def.item_id) < int(cost.amount):
			return false
	return true

func spend_resource_costs(costs: Array) -> bool:
	if not has_resource_costs(costs):
		return false
	for cost in costs:
		if cost == null or cost.item_def == null:
			continue
		var item_id: String = cost.item_def.item_id
		item_stock[item_id] = get_item_stock(item_id) - int(cost.amount)
	resources_updated.emit()
	return true

func consume_animal_feed_points(points: int) -> bool:
	if points <= 0:
		return true

	while animal_feed_points < points and get_item_stock(GameData.ITEM_ANIMAL_FEED) > 0:
		item_stock[GameData.ITEM_ANIMAL_FEED] = get_item_stock(GameData.ITEM_ANIMAL_FEED) - 1
		animal_feed_points += ANIMAL_FEED_POINTS_PER_BAG

	if animal_feed_points < points:
		resources_updated.emit()
		return false

	animal_feed_points -= points
	resources_updated.emit()
	return true

func get_animal_feed_points() -> int:
	return animal_feed_points

func add_animal_feed_points(points: int) -> void:
	if points <= 0:
		return
	animal_feed_points += points
	resources_updated.emit()

func get_blueprint_stock(blueprint_type: String) -> int:
	return int(blueprint_stock.get(blueprint_type, 0))

func consume_blueprint(blueprint_type: String) -> bool:
	var current := get_blueprint_stock(blueprint_type)
	if current < 1:
		return false

	blueprint_stock[blueprint_type] = current - 1
	resources_updated.emit()
	return true

func get_blueprint_price(blueprint_type: String) -> int:
	return GameData.get_blueprint_price(blueprint_type, int(blueprint_purchase_counts.get(blueprint_type, 0)))

func get_house_level(domain_id: String = GameData.WORKER_DOMAIN_FARM) -> int:
	return int(house_levels_by_domain.get(domain_id, 1))

func get_worker_price(domain_id: String = GameData.WORKER_DOMAIN_FARM) -> int:
	return GameData.get_worker_price(get_worker_count(domain_id))

func get_max_workers(domain_id: String = GameData.WORKER_DOMAIN_FARM) -> int:
	return GameData.get_max_workers(get_house_level(domain_id))

func get_worker_count(domain_id: String = "") -> int:
	if domain_id == "":
		var total_workers: int = 0
		for count in worker_counts_by_domain.values():
			total_workers += int(count)
		return total_workers
	return int(worker_counts_by_domain.get(domain_id, 0))

func buy_worker(domain_id: String = GameData.WORKER_DOMAIN_FARM) -> bool:
	if get_worker_count(domain_id) >= get_max_workers(domain_id):
		return false

	var price := get_worker_price(domain_id)
	if money < price:
		return false

	money -= price
	worker_counts_by_domain[domain_id] = get_worker_count(domain_id) + 1
	count_workers_bought = get_worker_count()
	resources_updated.emit()
	return true

func get_house_upgrade_price(domain_id: String = GameData.WORKER_DOMAIN_FARM) -> int:
	return GameData.get_house_upgrade_price(get_house_level(domain_id))

func upgrade_house(domain_id: String = GameData.WORKER_DOMAIN_FARM) -> bool:
	var current_level: int = get_house_level(domain_id)
	if current_level >= GameData.MAX_UPGRADE_LEVEL:
		return false

	var price := get_house_upgrade_price(domain_id)
	if money < price:
		return false

	money -= price
	house_levels_by_domain[domain_id] = current_level + 1
	house_level = get_house_level(GameData.WORKER_DOMAIN_FARM)
	resources_updated.emit()
	return true

func spend_money(amount: int) -> bool:
	if money < amount:
		return false

	money -= amount
	resources_updated.emit()
	return true

func sell_item(item_type: String) -> void:
	var item_def := GameData.get_item_def(item_type)
	if item_def == null:
		return

	if spend_item(item_type, 1):
		money += item_def.sell_price
		resources_updated.emit()

func buy_blueprint(blueprint_type: String) -> bool:
	var blueprint_def: BlueprintDefinition = GameData.get_blueprint_def(blueprint_type)
	if blueprint_def == null:
		return false

	var price := get_blueprint_price(blueprint_type)
	if money < price:
		return false
	if not has_resource_costs(blueprint_def.resource_costs):
		return false

	money -= price
	for cost in blueprint_def.resource_costs:
		if cost == null or cost.item_def == null:
			continue
		var item_id: String = cost.item_def.item_id
		item_stock[item_id] = get_item_stock(item_id) - int(cost.amount)
	blueprint_purchase_counts[blueprint_type] = int(blueprint_purchase_counts.get(blueprint_type, 0)) + 1
	blueprint_stock[blueprint_type] = get_blueprint_stock(blueprint_type) + 1
	resources_updated.emit()
	return true

func add_wheat(amount: int) -> void:
	add_item(GameData.ITEM_WHEAT, amount)

func add_egg(amount: int) -> void:
	add_item(GameData.ITEM_EGG, amount)

func add_milk(amount: int) -> void:
	add_item(GameData.ITEM_MILK, amount)

func add_cake(amount: int) -> void:
	add_item(GameData.ITEM_CAKE, amount)

func spend_flour(amount: int) -> bool:
	return spend_item(GameData.ITEM_FLOUR, amount)
