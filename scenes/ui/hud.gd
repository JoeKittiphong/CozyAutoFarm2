extends CanvasLayer

const ResourceItemScene = preload("res://scenes/ui/components/resource_item.tscn")
const ActionButtonScene = preload("res://scenes/ui/components/action_button.tscn")

var money_label: Label
var resource_labels: Dictionary = {}
var sell_buttons: Dictionary = {}
var animal_buttons: Dictionary = {}
var blueprint_buttons: Dictionary = {}
var current_upgrade_cell: Vector2i = Vector2i(-999, -999)

@onready var _resources_container: HBoxContainer = $TopBar/BarContent/ResourcesContainer
@onready var mill_btn: Button = $TopBar/BarContent/MillButton
@onready var shop_panel: PanelContainer = $SidePanels/ShopPanel
@onready var worker_panel: PanelContainer = $SidePanels/WorkerPanel
@onready var upgrade_panel: PanelContainer = $SidePanels/UpgradePanel
@onready var _shop_item_list: VBoxContainer = $SidePanels/ShopPanel/Content/ScrollContainer/ItemList
@onready var _worker_blueprint_list: VBoxContainer = $SidePanels/WorkerPanel/Content/ScrollContainer/BlueprintList
@onready var hire_worker_btn: Button = $SidePanels/WorkerPanel/Content/HireButton
@onready var upgrade_house_btn: Button = $SidePanels/WorkerPanel/Content/UpgradeHouseButton
@onready var stock_info_label: Label = $SidePanels/WorkerPanel/Content/StockLabel
@onready var upgrade_info_label: Label = $SidePanels/UpgradePanel/Content/InfoLabel
@onready var upgrade_btn: Button = $SidePanels/UpgradePanel/Content/ActionUpgradeButton
@onready var _shop_close_btn: Button = $SidePanels/ShopPanel/Content/CloseButton
@onready var _worker_close_btn: Button = $SidePanels/WorkerPanel/Content/CloseButton
@onready var _upgrade_close_btn: Button = $SidePanels/UpgradePanel/Content/CloseButton

@onready var _world: Node = get_node_or_null("/root/World")

func _ready() -> void:
	mill_btn.pressed.connect(_on_mill_pressed)
	hire_worker_btn.pressed.connect(_on_hire_pressed)
	upgrade_house_btn.pressed.connect(_upgrade_house)
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	_shop_close_btn.pressed.connect(_close_shop)
	_worker_close_btn.pressed.connect(_close_worker_panel)
	_upgrade_close_btn.pressed.connect(_close_upgrade_panel)

	_setup_top_bar()
	_setup_shop_ui()
	_setup_worker_ui()

	if InventoryManager:
		InventoryManager.resources_updated.connect(_on_resources_updated)
		_on_resources_updated()

func _setup_top_bar() -> void:
	for child in _resources_container.get_children():
		child.queue_free()
	resource_labels.clear()

	money_label = _create_resource_ui(_resources_container, "res://assets/sprites/coin_final.png", "Coins: 100")
	for item_type in GameData.get_item_order():
		var item_def := GameData.get_item_def(item_type)
		var icon_path: String = ""
		var label_text: String = item_type
		if item_def != null:
			icon_path = item_def.icon_path
			label_text = item_def.label
		resource_labels[item_type] = _create_resource_ui(_resources_container, icon_path, "%s: 0" % label_text)

func _setup_shop_ui() -> void:
	for child in _shop_item_list.get_children():
		child.queue_free()
	sell_buttons.clear()
	animal_buttons.clear()

	for item_type in GameData.get_sellable_item_order():
		var button = _create_action_button("", "_sell_item", [item_type])
		sell_buttons[item_type] = button
		_shop_item_list.add_child(button)

	for animal_type in GameData.get_shop_animal_order():
		var animal_button = _create_action_button("", "_on_buy_animal_pressed", [animal_type])
		animal_buttons[animal_type] = animal_button
		_shop_item_list.add_child(animal_button)

func _setup_worker_ui() -> void:
	for child in _worker_blueprint_list.get_children():
		child.queue_free()
	blueprint_buttons.clear()

	for blueprint_type in GameData.get_blueprint_order():
		var button = _create_action_button("", "_buy_blueprint", [blueprint_type])
		blueprint_buttons[blueprint_type] = button
		_worker_blueprint_list.add_child(button)

func _create_resource_ui(parent: Node, icon_path: String, start_val: String) -> Label:
	var resource_item: ResourceItemComponent = ResourceItemScene.instantiate()
	resource_item.configure(icon_path, start_val)
	parent.add_child(resource_item)
	return resource_item.get_label()

func _create_action_button(text_value: String, method_name: String, binds: Array = []) -> Button:
	var button: ActionButtonComponent = ActionButtonScene.instantiate()
	button.configure(text_value, self, method_name, binds)
	return button

func open_upgrade_ui(cell: Vector2i) -> void:
	var state = FarmManager.get_tile_state(cell)
	var valid_states = [
		FarmManager.TileState.TILLED,
		FarmManager.TileState.PLANTED,
		FarmManager.TileState.WATERED,
		FarmManager.TileState.GROWING,
		FarmManager.TileState.READY_TO_HARVEST,
		FarmManager.TileState.PROCESSOR,
		FarmManager.TileState.COOP,
		FarmManager.TileState.COW_PEN,
	]
	if state in valid_states:
		current_upgrade_cell = cell
		upgrade_panel.visible = true
		shop_panel.visible = false
		worker_panel.visible = false
		_on_resources_updated()

func _on_upgrade_pressed() -> void:
	if FarmManager.upgrade_tile(current_upgrade_cell):
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
	if InventoryManager.buy_worker():
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
	InventoryManager.upgrade_house()

func _sell_item(item_type: String) -> void:
	InventoryManager.sell_item(item_type)

func _buy_blueprint(blueprint_type: String) -> void:
	InventoryManager.buy_blueprint(blueprint_type)

func _on_buy_animal_pressed(animal_type: String) -> void:
	var animal_def := GameData.get_animal_def(animal_type)
	if animal_def == null:
		return
	if _world == null:
		_world = get_node_or_null("/root/World")
	if _world and _world.has_empty_pen(animal_def.pen_blueprint_type):
		if InventoryManager.spend_money(animal_def.price):
			_world._spawn_animal_at_shop(animal_type)

func _on_mill_pressed() -> void:
	InventoryManager.mill_paused = not InventoryManager.mill_paused
	mill_btn.text = "Mill: PAUSED" if InventoryManager.mill_paused else "Mill: ON"

func _on_resources_updated() -> void:
	money_label.text = "Coins: " + str(InventoryManager.money)

	for item_type in resource_labels.keys():
		var label: Label = resource_labels[item_type]
		var item_def := GameData.get_item_def(item_type)
		var item_label: String = item_type
		if item_def != null:
			item_label = item_def.label
		label.text = "%s: %d" % [item_label, InventoryManager.get_item_stock(item_type)]

	hire_worker_btn.text = "Hire Worker (%d/%d)\n-%d Coins" % [
		InventoryManager.count_workers_bought,
		InventoryManager.get_max_workers(),
		InventoryManager.get_worker_price()
	]
	hire_worker_btn.disabled = InventoryManager.count_workers_bought >= InventoryManager.get_max_workers()

	var house_price: int = InventoryManager.get_house_upgrade_price()
	if InventoryManager.house_level < GameData.MAX_UPGRADE_LEVEL:
		upgrade_house_btn.text = "Upgrade House (Lv %d)\n-%d Coins" % [InventoryManager.house_level, house_price]
		upgrade_house_btn.disabled = InventoryManager.money < house_price
	else:
		upgrade_house_btn.text = "Upgrade House (MAX Lv %d)" % GameData.MAX_UPGRADE_LEVEL
		upgrade_house_btn.disabled = true

	if upgrade_panel.visible:
		_update_upgrade_panel_info()

	for item_type in sell_buttons.keys():
		var sell_button: Button = sell_buttons[item_type]
		var item_def := GameData.get_item_def(item_type)
		var sell_label: String = item_type
		var sell_price: int = 0
		if item_def != null:
			sell_label = item_def.label
			sell_price = item_def.sell_price
		sell_button.text = "Sell %s (+%d Coin%s)" % [sell_label, sell_price, "" if sell_price == 1 else "s"]
		sell_button.disabled = InventoryManager.get_item_stock(item_type) < 1

	for blueprint_type in blueprint_buttons.keys():
		var blueprint_button: Button = blueprint_buttons[blueprint_type]
		var blueprint_def := GameData.get_blueprint_def(blueprint_type)
		var blueprint_label: String = blueprint_type
		if blueprint_def != null:
			blueprint_label = blueprint_def.label
		blueprint_button.text = "%s (-%d Coins)" % [blueprint_label, InventoryManager.get_blueprint_price(blueprint_type)]

	stock_info_label.text = "Stock: " + _get_blueprint_stock_summary(InventoryManager)

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
			animal_button.disabled = InventoryManager.money < price
		else:
			animal_button.text = "Buy %s (Need %s!)" % [label, pen_label]
			animal_button.disabled = true

func _get_blueprint_stock_summary(inv) -> String:
	var parts: Array[String] = []
	for blueprint_type in GameData.get_blueprint_order():
		var blueprint_def := GameData.get_blueprint_def(blueprint_type)
		var stock_short: String = blueprint_type.left(1)
		if blueprint_def != null and blueprint_def.stock_short != "":
			stock_short = blueprint_def.stock_short
		parts.append("%d %s" % [inv.get_blueprint_stock(blueprint_type), stock_short])
	return " | ".join(parts)

func _update_upgrade_panel_info() -> void:
	var lvl: int = FarmManager.get_tile_level(current_upgrade_cell)
	var type_str: String = "Plot"
	var effect_str: String = "Yield: %d -> %d" % [lvl, lvl + 1]

	var real_state = FarmManager.get_tile_state(current_upgrade_cell)
	if real_state == FarmManager.TileState.PROCESSOR:
		var processor_def := GameData.get_processor_def(FarmManager.get_processor_type(current_upgrade_cell))
		if processor_def != null:
			type_str = processor_def.label
		effect_str = "Efficiency: %d%% -> %d%%" % [int(pow(1.5, lvl - 1) * 100), int(pow(1.5, lvl) * 100)]

	if lvl < GameData.MAX_UPGRADE_LEVEL:
		var price: int = FarmManager.get_tile_upgrade_price(current_upgrade_cell)
		upgrade_info_label.text = "%s Lv %d\n%s\nCost: %d Coins" % [type_str, lvl, effect_str, price]
		upgrade_btn.disabled = InventoryManager.money < price
		upgrade_btn.visible = true
	else:
		upgrade_info_label.text = "%s Lv %d\n(MAX LEVEL)" % [type_str, lvl]
		upgrade_btn.visible = false
