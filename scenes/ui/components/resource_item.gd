extends HBoxContainer
class_name ResourceItemComponent

enum BindMode {
	NONE,
	MONEY,
	ITEM,
}

@onready var _icon: TextureRect = $Icon
@onready var _value_label: Label = $ValueLabel

var _bind_mode: int = BindMode.NONE
var _item_type: String = ""

func configure(icon_path: String, text: String) -> void:
	_icon.texture = load(icon_path) if icon_path != "" else null
	_value_label.text = text

func bind_money() -> void:
	_bind_mode = BindMode.MONEY
	_ensure_inventory_binding()
	_refresh_bound_value()

func bind_item(item_type: String) -> void:
	_bind_mode = BindMode.ITEM
	_item_type = item_type
	_ensure_inventory_binding()
	_refresh_bound_value()

func set_text(text: String) -> void:
	_value_label.text = text

func get_label() -> Label:
	return _value_label

func _ensure_inventory_binding() -> void:
	if not InventoryManager.resources_updated.is_connected(_refresh_bound_value):
		InventoryManager.resources_updated.connect(_refresh_bound_value)

func _refresh_bound_value() -> void:
	match _bind_mode:
		BindMode.MONEY:
			_value_label.text = "Coins: %d" % InventoryManager.money
		BindMode.ITEM:
			var item_def := GameData.get_item_def(_item_type)
			var label_text: String = _item_type
			if item_def != null:
				label_text = item_def.label
			_value_label.text = "%s: %d" % [label_text, InventoryManager.get_item_stock(_item_type)]

