extends Node

signal resources_updated

var wheat_stock: int = 0
var tomato_stock: int = 0
var potato_stock: int = 0
var flour_stock: int = 0
var egg_stock: int = 0
var milk_stock: int = 0
var cake_stock: int = 0
var money: int = 100

var bp_wheat: int = 0
var bp_tomato: int = 0
var bp_potato: int = 0
var bp_coop: int = 0
var bp_cow_pen: int = 0
var bp_bakery: int = 0
var bp_mill: int = 0

var count_wheat_bought: int = 0
var count_tomato_bought: int = 0
var count_potato_bought: int = 0
var count_coop_bought: int = 0
var count_cow_pen_bought: int = 0
var count_bakery_bought: int = 0
var count_mill_bought: int = 0
var count_workers_bought: int = 0

var mill_count: int = 0
var house_level: int = 1

var mill_paused: bool = false
const MILL_TIME: float = 5.0

func add_wheat(amount: int) -> void:
    wheat_stock += amount
    resources_updated.emit()

func _process(_delta: float) -> void:
    # Automatic Mill logic removed; moved to FarmManager/Worker delivery system
    pass

func get_worker_price() -> int:
    return 5 + (5 * count_workers_bought)

func get_max_workers() -> int:
    return house_level * 2

func buy_worker() -> bool:
    if count_workers_bought >= get_max_workers():
        return false
        
    var p = get_worker_price()
    if money >= p:
        money -= p
        count_workers_bought += 1
        resources_updated.emit()
        return true
    return false

func get_house_upgrade_price() -> int:
    return int(floor(100.0 * pow(2.0, house_level - 1)))

func upgrade_house() -> bool:
    if house_level >= 5: return false
    var p = get_house_upgrade_price()
    if money >= p:
        money -= p
        house_level += 1
        resources_updated.emit()
        return true
    return false

func add_egg(amount: int) -> void:
    egg_stock += amount
    resources_updated.emit()

func add_milk(amount: int) -> void:
    milk_stock += amount
    resources_updated.emit()

func add_cake(amount: int) -> void:
    cake_stock += amount
    resources_updated.emit()

func spend_flour(amount: int) -> bool:
    if flour_stock >= amount:
        flour_stock -= amount
        resources_updated.emit()
        return true
    return false

func spend_money(amount: int) -> bool:
    if money >= amount:
        money -= amount
        resources_updated.emit()
        return true
    return false

func sell_item(type: String) -> void:
    match type:
        "WHEAT":
            if wheat_stock > 0:
                wheat_stock -= 1
                money += 1
                resources_updated.emit()
        "TOMATO":
            if tomato_stock > 0:
                tomato_stock -= 1
                money += 1
                resources_updated.emit()
        "POTATO":
            if potato_stock > 0:
                potato_stock -= 1
                money += 1
                resources_updated.emit()
        "FLOUR":
            if flour_stock > 0:
                flour_stock -= 1
                money += 4
                resources_updated.emit()
        "EGG":
            if egg_stock > 0:
                egg_stock -= 1
                money += 5
                resources_updated.emit()
        "MILK":
            if milk_stock > 0:
                milk_stock -= 1
                money += 7
                resources_updated.emit()
        "CAKE":
            if cake_stock > 0:
                cake_stock -= 1
                money += 25
                resources_updated.emit()

func get_bp_price_wheat() -> int:
    return int(floor(5.0 * pow(1.1, count_wheat_bought)))

func get_bp_price_tomato() -> int:
    return int(floor(5.0 * pow(1.1, count_tomato_bought)))

func get_bp_price_potato() -> int:
    return int(floor(5.0 * pow(1.1, count_potato_bought)))

func get_bp_price_coop() -> int:
    return int(floor(15.0 * pow(1.15, count_coop_bought)))

func get_bp_price_cow_pen() -> int:
    return int(floor(20.0 * pow(1.2, count_cow_pen_bought)))

func get_bp_price_bakery() -> int:
    return int(floor(50.0 * pow(1.3, count_bakery_bought)))

func get_bp_price_mill() -> int:
    return int(floor(10.0 * pow(1.3, count_mill_bought)))

func buy_blueprint(type: String) -> bool:
    if type == "WHEAT":
        var p = get_bp_price_wheat()
        if money >= p:
            money -= p
            count_wheat_bought += 1
            bp_wheat += 1
            resources_updated.emit()
            return true
    elif type == "TOMATO":
        var p = get_bp_price_tomato()
        if money >= p:
            money -= p
            count_tomato_bought += 1
            bp_tomato += 1
            resources_updated.emit()
            return true
    elif type == "POTATO":
        var p = get_bp_price_potato()
        if money >= p:
            money -= p
            count_potato_bought += 1
            bp_potato += 1
            resources_updated.emit()
            return true
    elif type == "COOP":
        var p = get_bp_price_coop()
        if money >= p:
            money -= p
            count_coop_bought += 1
            bp_coop += 1
            resources_updated.emit()
            return true
    elif type == "COW_PEN":
        var p = get_bp_price_cow_pen()
        if money >= p:
            money -= p
            count_cow_pen_bought += 1
            bp_cow_pen += 1
            resources_updated.emit()
            return true
    elif type == "BAKERY":
        var p = get_bp_price_bakery()
        if money >= p:
            money -= p
            count_bakery_bought += 1
            bp_bakery += 1
            resources_updated.emit()
            return true
    elif type == "MILL":
        var p = get_bp_price_mill()
        if money >= p:
            money -= p
            count_mill_bought += 1
            bp_mill += 1
            resources_updated.emit()
            return true
    return false
