extends Resource
class_name AnimalDefinition

@export var animal_id: String = ""
@export var label: String = ""
@export var price: int = 0
@export var pen_blueprint_type: String = ""
@export_file("*.png") var icon_path: String = ""
@export_file("*.gd") var script_path: String = "res://entities/animals/farm_animal.gd"
@export var group_name: String = ""
@export var feed_item_id: String = ""
@export var feed_amount: int = 1
@export var product_item_id: String = ""
@export var produce_time: float = 10.0
@export var ready_state_name: String = "READY"
@export var move_speed: float = 30.0
@export var sprite_scale: float = 0.5
@export var wander_padding: float = 10.0
@export var level_textures: Array[String] = []
