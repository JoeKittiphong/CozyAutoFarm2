extends Resource
class_name ItemDefinition

@export var item_id: String = ""
@export var label: String = ""
@export_file("*.png") var icon_path: String = ""
@export var sell_price: int = 0
@export var carry_amount: int = 1
