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

	# เพิ่มการแสดงแต้มอาหารสะสม (Feed Points) ท้ายรายการ
	var pts: int = InventoryManager.get_animal_feed_points()
	if pts > 0 or not show_only_owned:
		var pts_item := ResourceItemScene.instantiate()
		pts_item.configure("res://assets/sprites/animal_feed_bag.png", "Feed Points: %d" % pts)
		pts_item.modulate = Color(0.8, 1.0, 0.8) # สีเขียวสะดุดตาเพื่อให้แยกจากไอเทมปกติ
		add_child(pts_item)
