extends Node

const GameData = preload("res://systems/core/game_data.gd")

signal resources_updated

var money: int = 100
var mill_count: int = 0
var house_level: int = 1
var mill_paused: bool = false

var item_stock: Dictionary = {}
var blueprint_stock: Dictionary = {}
var blueprint_purchase_counts: Dictionary = {}
var count_workers_bought: int = 0

const MILL_TIME: float = 5.0

func _ready() -> void:
	for item_type in GameData.get_item_order():
		item_stock[item_type] = 0

	for blueprint_type in GameData.get_blueprint_order():
		blueprint_stock[blueprint_type] = 0
		blueprint_purchase_counts[blueprint_type] = 0

func _process(_delta: float) -> void:
	pass

func get_item_stock(item_type: String) -> int:
	return int(item_stock.get(item_type, 0))

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

func get_worker_price() -> int:
	return GameData.get_worker_price(count_workers_bought)

func get_max_workers() -> int:
	return GameData.get_max_workers(house_level)

func buy_worker() -> bool:
	if count_workers_bought >= get_max_workers():
		return false

	var price := get_worker_price()
	if money < price:
		return false

	money -= price
	count_workers_bought += 1
	resources_updated.emit()
	return true

func get_house_upgrade_price() -> int:
	return GameData.get_house_upgrade_price(house_level)

func upgrade_house() -> bool:
	if house_level >= GameData.MAX_UPGRADE_LEVEL:
		return false

	var price := get_house_upgrade_price()
	if money < price:
		return false

	money -= price
	house_level += 1
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
	var price := get_blueprint_price(blueprint_type)
	if money < price:
		return false

	if GameData.get_blueprint_def(blueprint_type) == null:
		return false

	money -= price
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

