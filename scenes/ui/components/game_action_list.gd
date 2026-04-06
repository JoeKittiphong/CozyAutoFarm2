extends VBoxContainer
class_name GameActionListComponent

const ActionButtonScene = preload("res://scenes/ui/components/action_button.tscn")

signal action_selected(action_id: String)

@export_enum("sellable_items", "shop_animals", "blueprints") var list_kind: String = "sellable_items"
@export var blueprint_shop_category: String = ""
@export var blueprint_placement_filters: PackedStringArray = []

var _buttons_by_id: Dictionary = {}
var _order: Array[String] = []

func _ready() -> void:
	repopulate()

func repopulate() -> void:
	for child in get_children():
		child.queue_free()
	_buttons_by_id.clear()
	_order = _resolve_order()

	for action_id in _order:
		var button: ActionButtonComponent = ActionButtonScene.instantiate()
		button.configure_action(action_id)
		button.action_pressed.connect(_on_button_action_pressed)
		_buttons_by_id[action_id] = button
		add_child(button)

func get_buttons() -> Dictionary:
	return _buttons_by_id

func get_order() -> Array[String]:
	return _order.duplicate()

func _resolve_order() -> Array[String]:
	match list_kind:
		"shop_animals":
			return GameData.get_shop_animal_order()
		"blueprints":
			var blueprint_ids: Array[String] = []
			if blueprint_shop_category != "":
				blueprint_ids = GameData.get_blueprint_order_by_shop_category(blueprint_shop_category)
			else:
				blueprint_ids = GameData.get_blueprint_order()
			if blueprint_placement_filters.is_empty():
				return blueprint_ids
			var filtered: Array[String] = []
			for blueprint_id in blueprint_ids:
				var blueprint_def: BlueprintDefinition = GameData.get_blueprint_def(blueprint_id)
				if blueprint_def == null:
					continue
				if blueprint_placement_filters.has(blueprint_def.placement_type):
					filtered.append(blueprint_id)
			return filtered
		_:
			return GameData.get_sellable_item_order()

func _on_button_action_pressed(action_id: String) -> void:
	action_selected.emit(action_id)
