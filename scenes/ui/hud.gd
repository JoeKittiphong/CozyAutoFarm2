extends CanvasLayer

const GameData = preload("res://systems/core/game_data.gd")
const ResourceItemScene = preload("res://scenes/ui/components/resource_item.tscn")
const ActionButtonScene = preload("res://scenes/ui/components/action_button.tscn")

var money_label: Label
var resource_labels: Dictionary = {}
var mill_btn: Button

var shop_panel: PanelContainer
var worker_panel: PanelContainer

var sell_buttons: Dictionary = {}
var animal_buttons: Dictionary = {}
var blueprint_buttons: Dictionary = {}

var hire_worker_btn: Button
var upgrade_house_btn: Button
var stock_info_label: Label

var upgrade_panel: PanelContainer
var upgrade_info_label: Label
var upgrade_btn: Button
var current_upgrade_cell: Vector2i = Vector2i(-999, -999)

@onready var _inventory_manager: Node = get_node("/root/InventoryManager")
@onready var _farm_manager: Node = get_node("/root/FarmManager")
@onready var _world: Node = get_node_or_null("/root/World")

func _ready() -> void:
	var top_panel = PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.custom_minimum_size = Vector2(0, 40)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.1, 0.9)
	top_panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)

	money_label = _create_resource_ui(hbox, "res://assets/sprites/coin_final.png", "Coins: 100")
	for item_type in GameData.get_item_order():
		var item_def := GameData.get_item_def(item_type)
		resource_labels[item_type] = _create_resource_ui(
			hbox,
			item_def.icon_path if item_def != null else "",
			"%s: 0" % (item_def.label if item_def != null else item_type)
		)

	mill_btn = Button.new()
	mill_btn.text = "Mill: ON"
	mill_btn.pressed.connect(_on_mill_pressed)
	hbox.add_child(mill_btn)

	top_panel.add_child(hbox)
	add_child(top_panel)

	_setup_shop_ui()
	_setup_worker_ui()
	_setup_upgrade_ui()

	if _inventory_manager:
		_inventory_manager.resources_updated.connect(_on_resources_updated)
		_on_resources_updated()

func _create_resource_ui(parent: Node, icon_path: String, start_val: String) -> Label:
	var resource_item: ResourceItemComponent = ResourceItemScene.instantiate()
	resource_item.configure(icon_path, start_val)
	parent.add_child(resource_item)
	return resource_item.get_label()

func _setup_shop_ui() -> void:
	shop_panel = _create_side_panel(Color(0.2, 0.15, 0.1, 0.95), Color(0.8, 0.6, 0.2))
	var vbox = _create_panel_content(shop_panel)

	var title = Label.new()
	title.text = "--- SHOP ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for item_type in GameData.get_sellable_item_order():
		var button = _create_action_button("", "_sell_item", [item_type])
		sell_buttons[item_type] = button
		vbox.add_child(button)

	for animal_type in GameData.get_shop_animal_order():
		var animal_button = _create_action_button("", "_on_buy_animal_pressed", [animal_type])
		animal_buttons[animal_type] = animal_button
		vbox.add_child(animal_button)

	var close_btn = _create_action_button("Close", "_close_shop")
	vbox.add_child(close_btn)

func _setup_worker_ui() -> void:
	worker_panel = _create_side_panel(Color(0.15, 0.2, 0.1, 0.95), Color(0.4, 0.8, 0.2))
	var vbox = _create_panel_content(worker_panel)

	var title = Label.new()
	title.text = "--- WORKER HOUSE ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	hire_worker_btn = _create_action_button("", "_on_hire_pressed")
	vbox.add_child(hire_worker_btn)

	upgrade_house_btn = _create_action_button("", "_upgrade_house")
	vbox.add_child(upgrade_house_btn)

	var title2 = Label.new()
	title2.text = "--- BUY BLUEPRINTS ---"
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title2)

	for blueprint_type in GameData.get_blueprint_order():
		var button = _create_action_button("", "_buy_blueprint", [blueprint_type])
		blueprint_buttons[blueprint_type] = button
		vbox.add_child(button)

	stock_info_label = Label.new()
	stock_info_label.text = "Stock: "
	stock_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock_info_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	vbox.add_child(stock_info_label)

	var close_btn = _create_action_button("Close", "_close_worker_panel")
	vbox.add_child(close_btn)

func _setup_upgrade_ui() -> void:
	upgrade_panel = _create_side_panel(Color(0.05, 0.15, 0.1, 0.95), Color(0.2, 0.9, 0.5))
	var vbox = _create_panel_content(upgrade_panel)

	var title = Label.new()
	title.text = "--- UPGRADE ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	vbox.add_child(title)

	upgrade_info_label = Label.new()
	upgrade_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(upgrade_info_label)

	upgrade_btn = _create_action_button("Upgrade", "_on_upgrade_pressed")
	upgrade_btn.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(upgrade_btn)

	var close_btn = _create_action_button("Close", "_close_upgrade_panel")
	close_btn.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(close_btn)

func _create_side_panel(bg_color: Color, border_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_MINSIZE, 0)
	panel.offset_top = 40
	panel.custom_minimum_size.x = 350
	panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_bottom = 4
	style.border_width_top = 4
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_color = border_color
	style.corner_radius_bottom_right = 10
	style.corner_radius_top_right = 10
	panel.add_theme_stylebox_override("panel", style)

	add_child(panel)
	return panel

func _create_panel_content(panel: PanelContainer) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 15)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)

	panel.add_child(vbox)
	return vbox

func _create_action_button(text_value: String, method_name: String, binds: Array = []) -> Button:
	var button: ActionButtonComponent = ActionButtonScene.instantiate()
	button.configure(text_value, self, method_name, binds)
	return button

func open_upgrade_ui(cell: Vector2i) -> void:
	var state = _farm_manager.get_tile_state(cell)

	var valid_states = [
		_farm_manager.TileState.TILLED, _farm_manager.TileState.PLANTED, _farm_manager.TileState.WATERED,
		_farm_manager.TileState.GROWING, _farm_manager.TileState.READY_TO_HARVEST,
		_farm_manager.TileState.PROCESSOR,
		_farm_manager.TileState.COOP, _farm_manager.TileState.COW_PEN
	]

	if state in valid_states:
		current_upgrade_cell = cell
		upgrade_panel.visible = true
		shop_panel.visible = false
		worker_panel.visible = false
		_on_resources_updated()

func _on_upgrade_pressed() -> void:
	if _farm_manager.upgrade_tile(current_upgrade_cell):
		_on_resources_updated()

func toggle_shop() -> void:
	shop_panel.visible = not shop_panel.visible
	if shop_panel.visible:
		worker_panel.visible = false
		upgrade_panel.visible = false

func toggle_worker_house() -> void:
	worker_panel.visible = not worker_panel.visible
	if worker_panel.visible:
		shop_panel.visible = false
		upgrade_panel.visible = false

func _on_hire_pressed() -> void:
	if _inventory_manager.buy_worker():
		if _world == null:
			_world = get_node_or_null("/root/World")
		if _world:
			_world._spawn_worker()

func _close_shop() -> void:
	shop_panel.visible = false

func _close_worker_panel() -> void:
	worker_panel.visible = false

func _close_upgrade_panel() -> void:
	upgrade_panel.visible = false

func _upgrade_house() -> void:
	_inventory_manager.upgrade_house()

func _sell_item(item_type: String) -> void:
	_inventory_manager.sell_item(item_type)

func _buy_blueprint(blueprint_type: String) -> void:
	_inventory_manager.buy_blueprint(blueprint_type)

func _on_buy_animal_pressed(animal_type: String) -> void:
	var animal_def := GameData.get_animal_def(animal_type)
	if animal_def == null:
		return
	if _world == null:
		_world = get_node_or_null("/root/World")
	if _world and _world.has_empty_pen(animal_def.pen_blueprint_type):
		if _inventory_manager.spend_money(animal_def.price):
			_world._spawn_animal_at_shop(animal_type)

func _on_mill_pressed() -> void:
	_inventory_manager.mill_paused = not _inventory_manager.mill_paused
	mill_btn.text = "Mill: PAUSED" if _inventory_manager.mill_paused else "Mill: ON"

func _on_resources_updated() -> void:
	money_label.text = "Coins: " + str(_inventory_manager.money)

	for item_type in resource_labels.keys():
		var label: Label = resource_labels[item_type]
		var item_def := GameData.get_item_def(item_type)
		label.text = "%s: %d" % [item_def.label if item_def != null else item_type, _inventory_manager.get_item_stock(item_type)]

	if hire_worker_btn:
		hire_worker_btn.text = "Hire Worker (%d/%d)\n-%d Coins" % [
			_inventory_manager.count_workers_bought,
			_inventory_manager.get_max_workers(),
			_inventory_manager.get_worker_price()
		]
		hire_worker_btn.disabled = _inventory_manager.count_workers_bought >= _inventory_manager.get_max_workers()

	if upgrade_house_btn:
		var house_price: int = _inventory_manager.get_house_upgrade_price()
		if _inventory_manager.house_level < GameData.MAX_UPGRADE_LEVEL:
			upgrade_house_btn.text = "Upgrade House (Lv %d)\n-%d Coins" % [_inventory_manager.house_level, house_price]
			upgrade_house_btn.disabled = _inventory_manager.money < house_price
		else:
			upgrade_house_btn.text = "Upgrade House (MAX Lv %d)" % GameData.MAX_UPGRADE_LEVEL
			upgrade_house_btn.disabled = true

	if upgrade_panel and upgrade_panel.visible:
		_update_upgrade_panel_info()

	for item_type in sell_buttons.keys():
		var sell_button: Button = sell_buttons[item_type]
		var item_def := GameData.get_item_def(item_type)
		var sell_label: String = item_type
		var sell_price: int = 0
		if item_def != null:
			sell_label = item_def.label
			sell_price = item_def.sell_price
		sell_button.text = "Sell %s (+%d Coin%s)" % [
			sell_label,
			sell_price,
			"" if sell_price == 1 else "s"
		]
		sell_button.disabled = _inventory_manager.get_item_stock(item_type) < 1

	for blueprint_type in blueprint_buttons.keys():
		var blueprint_button: Button = blueprint_buttons[blueprint_type]
		var blueprint_def := GameData.get_blueprint_def(blueprint_type)
		var blueprint_label: String = blueprint_type
		if blueprint_def != null:
			blueprint_label = blueprint_def.label
		blueprint_button.text = "%s (-%d Coins)" % [
			blueprint_label,
			_inventory_manager.get_blueprint_price(blueprint_type)
		]

	stock_info_label.text = "Stock: " + _get_blueprint_stock_summary(_inventory_manager)

	if _world == null:
		_world = get_node_or_null("/root/World")
	for animal_type in animal_buttons.keys():
		var animal_button: Button = animal_buttons[animal_type]
		var animal_def := GameData.get_animal_def(animal_type)
		if animal_def == null:
			continue
		var pen_type: String = animal_def.pen_blueprint_type
		var price: int = animal_def.price
		var label: String = animal_def.label
		var pen_def := GameData.get_blueprint_def(pen_type)
		var pen_label: String = pen_type
		if pen_def != null:
			pen_label = pen_def.label
		if _world and _world.has_empty_pen(pen_type):
			animal_button.text = "Buy %s (-%d Coins)" % [label, price]
			animal_button.disabled = _inventory_manager.money < price
		else:
			animal_button.text = "Buy %s (Need %s!)" % [label, pen_label]
			animal_button.disabled = true

func _get_blueprint_stock_summary(inv: Node) -> String:
	var parts: Array[String] = []
	for blueprint_type in GameData.get_blueprint_order():
		var blueprint_def := GameData.get_blueprint_def(blueprint_type)
		var stock_short: String = blueprint_type.left(1)
		if blueprint_def != null and blueprint_def.stock_short != "":
			stock_short = blueprint_def.stock_short
		parts.append("%d %s" % [
			inv.get_blueprint_stock(blueprint_type),
			stock_short
		])
	return " | ".join(parts)

func _update_upgrade_panel_info() -> void:
	var lvl = _farm_manager.get_tile_level(current_upgrade_cell)

	var type_str = "Plot"
	var effect_str = "Yield: %d -> %d" % [lvl, lvl + 1]

	var real_state = _farm_manager.get_tile_state(current_upgrade_cell)
	if real_state == _farm_manager.TileState.PROCESSOR:
		var processor_def := GameData.get_processor_def(_farm_manager.get_processor_type(current_upgrade_cell))
		type_str = processor_def.label if processor_def != null else "Processor"
		effect_str = "Efficiency: %d%% -> %d%%" % [int(pow(1.5, lvl - 1) * 100), int(pow(1.5, lvl) * 100)]

	if lvl < GameData.MAX_UPGRADE_LEVEL:
		var price = _farm_manager.get_tile_upgrade_price(current_upgrade_cell)
		upgrade_info_label.text = "%s Lv %d\n%s\nCost: %d Coins" % [type_str, lvl, effect_str, price]
		upgrade_btn.disabled = _inventory_manager.money < price
		upgrade_btn.visible = true
	else:
		upgrade_info_label.text = "%s Lv %d\n(MAX LEVEL)" % [type_str, lvl]
		upgrade_btn.visible = false







