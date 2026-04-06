extends Resource
class_name WorldResourceDefinition

@export var resource_id: String = ""
@export var label: String = ""
@export var tile_source_id: int = -1
@export var tile_atlas_coords: Vector2i = Vector2i.ZERO
@export var drop_item_def: ItemDefinition
@export var drop_amount: int = 1
@export var gather_duration: float = 1.0
@export var blocks_movement: bool = true
