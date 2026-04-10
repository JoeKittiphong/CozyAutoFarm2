extends PanelContainer
class_name BottomStorageBarController

const STORAGE_ITEMS_BY_TAB := {
	GameData.WORKER_DOMAIN_FARM: [
		GameData.ITEM_WHEAT,
		GameData.ITEM_TOMATO,
		GameData.ITEM_POTATO,
		GameData.ITEM_EGG,
		GameData.ITEM_MILK,
	],
	GameData.WORKER_DOMAIN_FACTORY: [
		GameData.ITEM_FLOUR,
		GameData.ITEM_ANIMAL_FEED,
		GameData.ITEM_FISH,
		GameData.ITEM_CAKE,
		GameData.ITEM_TOMATO_SAUCE,
	],
	GameData.WORKER_DOMAIN_GATHERING: [
		GameData.ITEM_WOOD,
		GameData.ITEM_STONE,
	],
}

var _storage_item_buttons: Dictionary = {}
var _selected_storage_item_type: String = ""
var _current_storage_tab: String = GameData.WORKER_DOMAIN_FARM

@onready var _bottom_storage_items: HBoxContainer = $Content/StorageLayout/StorageItems
@onready var _target_popup: PanelContainer = get_node_or_null("../TargetPopup")
@onready var _target_popup_stock_label: Label = get_node_or_null("../TargetPopup/Content/StockLabel")
@onready var _target_popup_spinbox: SpinBox = get_node_or_null("../TargetPopup/Content/TargetSpinBox")
@onready var _target_popup_close_btn: Button = get_node_or_null("../TargetPopup/Content/CloseButton")

func _ready() -> void:
	if _target_popup_close_btn != null:
		_target_popup_close_btn.pressed.connect(_close_target_popup)
	if _target_popup_spinbox != null:
		_target_popup_spinbox.value_changed.connect(_on_popup_target_value_changed)
	_rebuild_bottom_storage_items()

func is_open() -> bool:
	return visible

func get_current_tab() -> String:
	return _current_storage_tab

func refresh_targets() -> void:
	for item_type in _storage_item_buttons.keys():
		var entry: Dictionary = _storage_item_buttons[item_type]
		var storage_button: Button = entry.get("button", null)
		var badge: Label = entry.get("badge", null)
		if storage_button == null:
			continue
		var stock: int = InventoryManager.get_item_stock(item_type)
		var target: int = InventoryManager.get_item_target(item_type)
		storage_button.disabled = false
		storage_button.tooltip_text = "%s: %d / %d" % [item_type.capitalize(), stock, target]
		if badge != null:
			badge.text = "%d/%d" % [stock, target]
		if InventoryManager.is_item_below_target(item_type):
			storage_button.modulate = Color(1.0, 0.85, 0.45, 1.0)
		else:
			storage_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if _selected_storage_item_type != "":
		_refresh_target_popup()

func open_panel() -> void:
	visible = true

func close_panel() -> void:
	visible = false
	_close_target_popup()

func set_tab(tab_id: String) -> void:
	if _current_storage_tab == tab_id:
		return
	_current_storage_tab = tab_id
	_close_target_popup()
	_rebuild_bottom_storage_items()
	refresh_targets()

func toggle_tab(tab_id: String) -> void:
	var same_tab: bool = _current_storage_tab == tab_id
	if visible and same_tab:
		close_panel()
		refresh_targets()
		return
	open_panel()
	set_tab(tab_id)
	refresh_targets()

func _rebuild_bottom_storage_items() -> void:
	for child in _bottom_storage_items.get_children():
		child.queue_free()
	_storage_item_buttons.clear()

	for item_type in _get_storage_items_for_current_tab():
		var item_def: ItemDefinition = GameData.get_item_def(item_type)
		if item_def == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(35, 35)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.text = ""
		btn.pressed.connect(_open_target_popup.bind(item_type))
		var icon_tex = ResourceLoader.load(item_def.icon_path)
		if icon_tex != null:
			btn.icon = icon_tex
		var badge := Label.new()
		badge.text = "0/0"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 9)
		badge.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		badge.set_anchors_preset(Control.PRESET_TOP_WIDE)
		badge.offset_top = -2.0
		badge.offset_bottom = 10.0
		btn.add_child(badge)
		_bottom_storage_items.add_child(btn)
		_storage_item_buttons[item_type] = {
			"button": btn,
			"badge": badge,
		}

func _get_storage_items_for_current_tab() -> Array[String]:
	var configured: Array = STORAGE_ITEMS_BY_TAB.get(_current_storage_tab, [])
	var result: Array[String] = []
	for item_type in configured:
		result.append(String(item_type))
	return result

func _open_target_popup(item_type: String) -> void:
	if _target_popup == null:
		return
	_selected_storage_item_type = item_type
	var source_entry: Dictionary = _storage_item_buttons.get(item_type, {})
	var source_button: Button = source_entry.get("button", null)
	if source_button != null:
		var button_pos: Vector2 = source_button.get_global_position()
		var popup_x: float = clamp(button_pos.x - 48.0, 8.0, max(8.0, get_viewport().get_visible_rect().size.x - _target_popup.custom_minimum_size.x - 8.0))
		var popup_y: float = button_pos.y - 150.0
		_target_popup.position = Vector2(popup_x, max(60.0, popup_y))
	_refresh_target_popup()
	_target_popup.visible = true

func _refresh_target_popup() -> void:
	if _target_popup == null:
		return
	if _selected_storage_item_type == "":
		return
	var item_def: ItemDefinition = GameData.get_item_def(_selected_storage_item_type)
	if item_def == null:
		return
	if _target_popup_stock_label != null:
		_target_popup_stock_label.text = "%s\nStock %d / Target %d" % [
			item_def.label,
			InventoryManager.get_item_stock(_selected_storage_item_type),
			InventoryManager.get_item_target(_selected_storage_item_type),
		]
	if _target_popup_spinbox != null and int(_target_popup_spinbox.value) != InventoryManager.get_item_target(_selected_storage_item_type):
		_target_popup_spinbox.value = InventoryManager.get_item_target(_selected_storage_item_type)

func _close_target_popup() -> void:
	if _target_popup != null:
		_target_popup.visible = false
	_selected_storage_item_type = ""

func _on_popup_target_value_changed(value: float) -> void:
	if _selected_storage_item_type == "":
		return
	InventoryManager.set_item_target(_selected_storage_item_type, int(value))
