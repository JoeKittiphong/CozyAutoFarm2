extends Resource
class_name ProcessorDefinition

@export var processor_type: String = ""
@export var label: String = ""
@export var base_duration: float = 1.0
@export var ready_state_name: String = "READY"
@export_file("*.png") var ready_texture_path: String = ""
@export var deliver_storage_pos: Vector2i = Vector2i.ZERO
@export var collect_storage_pos: Vector2i = Vector2i.ZERO
@export var inputs: Array[ResourceAmountDefinition] = []
@export var outputs: Array[ResourceAmountDefinition] = []
