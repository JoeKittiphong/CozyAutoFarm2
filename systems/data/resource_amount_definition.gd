extends Resource
class_name ResourceAmountDefinition

const ItemDefinition = preload("res://systems/data/item_definition.gd")

@export var item_def: ItemDefinition
@export var amount: int = 1
