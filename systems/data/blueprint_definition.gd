extends Resource
class_name BlueprintDefinition

@export var blueprint_id: String = ""
@export var label: String = ""
@export var stock_short: String = ""
@export var base_price: float = 0.0
@export var growth: float = 1.0
@export var placement_type: String = ""
@export var placement_surface: String = "LAND"
@export var shop_category: String = "SHOP"
@export var crop_type: String = ""
@export var tile_type: String = ""
@export var processor_type: String = ""
@export_file("*.png") var texture_path: String = ""
@export var level_textures: Array[String] = []
@export var level_sprout_textures: Array[String] = []
@export var level_ready_textures: Array[String] = []
@export var visual_size_in_tiles: Vector2 = Vector2.ONE
@export var visual_scale: float = 1.0
@export var visual_y_offset_tiles: float = 0.0
@export var resource_costs: Array[ResourceAmountDefinition] = []
