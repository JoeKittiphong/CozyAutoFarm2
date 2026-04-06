extends VBoxContainer
class_name GameResourceListComponent

const ResourceItemScene = preload("res://scenes/ui/components/resource_item.tscn")

@export var show_only_owned: bool = true

func _ready() -> void:
	repopulate()
	if not InventoryManager.resources_updated.is_connected(repopulate):
		InventoryManager.resources_updated.connect(repopulate)

func repopulate() -> void:
	for child in get_children():
		child.queue_free()

	for item_type in GameData.get_item_order():
		var stock: int = InventoryManager.get_item_stock(item_type)
		if show_only_owned and stock < 1:
			continue

		var item_def = GameData.get_item_def(item_type)
		var icon_path: String = ""
		if item_def != null:
			icon_path = item_def.icon_path

		var resource_item: ResourceItemComponent = ResourceItemScene.instantiate()
		resource_item.configure(icon_path, "")
		resource_item.bind_item(item_type)
		add_child(resource_item)
