extends Node

signal resources_updated

var wheat_stock: int = 0
var flour_stock: int = 0
var egg_stock: int = 0
var milk_stock: int = 0

var mill_paused: bool = false
const MILL_TIME: float = 5.0
var _mill_timer: float = 0.0

func add_wheat(amount: int) -> void:
    wheat_stock += amount
    resources_updated.emit()

func _process(delta: float) -> void:
    if not mill_paused and wheat_stock >= 3:
        _mill_timer += delta
        if _mill_timer >= MILL_TIME:
            _mill_timer -= MILL_TIME
            wheat_stock -= 3
            flour_stock += 1
            resources_updated.emit()

func buy_worker() -> bool:
    if flour_stock >= 2:
        flour_stock -= 2
        resources_updated.emit()
        return true
    return false

func add_egg(amount: int) -> void:
    egg_stock += amount
    resources_updated.emit()

func add_milk(amount: int) -> void:
    milk_stock += amount
    resources_updated.emit()

func spend_flour(amount: int) -> bool:
    if flour_stock >= amount:
        flour_stock -= amount
        resources_updated.emit()
        return true
    return false
