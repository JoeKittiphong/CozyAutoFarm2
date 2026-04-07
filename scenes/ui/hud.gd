extends CanvasLayer

const ResourceItemScene = preload("res://scenes/ui/components/resource_item.tscn")

var current_upgrade_cell: Vector2i = Vector2i(-999, -999)
var sell_buttons: Dictionary = {}
var animal_buttons: Dictionary = {}
var blueprint_buttons: Dictionary = {}
var worker_assignment_buttons: Dictionary = {}
var _warehouse_tween: Tween
var _hide_warehouse_after_tween: bool = false
var _selected_worker: FarmWorker = null
var _current_worker_house_domain: String = GameData.WORKER_DOMAIN_FARM
var _target_controls: Dictionary = {}

@onready var _resources_container: HBoxContainer = $TopBar/BarContent/ResourcesContainer
@onready var _warehouse_btn: Button = $TopBar/BarContent/WarehouseButton
@onready var _targets_btn: Button = $TopBar/BarContent/TargetsButton
@onready var _workers_btn: Button = $TopBar/BarContent/WorkersButton
@onready var mill_btn: Button = $TopBar/BarContent/MillButton
@onready var warehouse_panel: PanelContainer = $SidePanels/WarehousePanel
@onready var targets_panel: PanelContainer = $SidePanels/TargetsPanel
@onready var worker_manage_panel: PanelContainer = $SidePanels/WorkerManagePanel
@onready var shop_panel: PanelContainer = $SidePanels/ShopPanel
@onready var worker_panel: PanelContainer = $SidePanels/WorkerPanel
@onready var upgrade_panel: PanelContainer = $SidePanels/UpgradePanel
@onready var _warehouse_close_btn: Button = $SidePanels/WarehousePanel/Content/CloseButton
@onready var _warehouse_resource_list: GameResourceListComponent = $SidePanels/WarehousePanel/Content/ScrollContainer/ResourceList
@onready var _targets_close_btn: Button = $SidePanels/TargetsPanel/Content/CloseButton
@onready var _target_list: VBoxContainer = $SidePanels/TargetsPanel/Content/ScrollContainer/TargetList
@onready var _worker_manage_close_btn: Button = $SidePanels/WorkerManagePanel/Content/CloseButton
@onready var _worker_manage_list: VBoxContainer = $SidePanels/WorkerManagePanel/Content/WorkerScroll/WorkerList
@onready var _worker_manage_selected_label: Label = $SidePanels/WorkerManagePanel/Content/SelectedWorkerLabel
@onready var _worker_manage_info_label: Label = $SidePanels/WorkerManagePanel/Content/InfoLabel
@onready var _worker_manage_mode_label: Label = $SidePanels/WorkerManagePanel/Content/ModeLabel
@onready var _worker_manage_mode: OptionButton = $SidePanels/WorkerManagePanel/Content/ModeOption
@onready var _worker_manage_role_label: Label = $SidePanels/WorkerManagePanel/Content/RoleLabel
@onready var _worker_manage_role: OptionButton = $SidePanels/WorkerManagePanel/Content/RoleOption
@onready var _worker_manage_target_label: Label = $SidePanels/WorkerManagePanel/Content/TargetLabel
@onready var _worker_manage_target: OptionButton = $SidePanels/WorkerManagePanel/Content/TargetOption
@onready var _worker_manage_fallback: CheckButton = $SidePanels/WorkerManagePanel/Content/FallbackCheck
@onready var _worker_manage_apply_btn: Button = $SidePanels/WorkerManagePanel/Content/ApplyButton
@onready var _worker_manage_reset_btn: Button = $SidePanels/WorkerManagePanel/Content/ResetButton
@onready var _sell_list: GameActionListComponent = $SidePanels/ShopPanel/Content/ScrollContainer/ScrollContent/SellList
@onready var _seed_blueprint_list: GameActionListComponent = $SidePanels/ShopPanel/Content/ScrollContainer/ScrollContent/SeedBlueprintList
@onready var _building_blueprint_list: GameActionListComponent = $SidePanels/ShopPanel/Content/ScrollContainer/ScrollContent/BuildingBlueprintList
@onready var _animal_list: GameActionListComponent = $SidePanels/ShopPanel/Content/ScrollContainer/ScrollContent/AnimalList
@onready var _worker_panel_title: Label = $SidePanels/WorkerPanel/Content/Title
@onready var hire_worker_btn: Button = $SidePanels/WorkerPanel/Content/HireButton
@onready var upgrade_house_btn: Button = $SidePanels/WorkerPanel/Content/UpgradeHouseButton
@onready var upgrade_info_label: Label = $SidePanels/UpgradePanel/Content/InfoLabel
@onready var upgrade_btn: Button = $SidePanels/UpgradePanel/Content/ActionUpgradeButton
@onready var _shop_close_btn: Button = $SidePanels/ShopPanel/Content/CloseButton
@onready var _worker_close_btn: Button = $SidePanels/WorkerPanel/Content/CloseButton
@onready var _upgrade_close_btn: Button = $SidePanels/UpgradePanel/Content/CloseButton

@onready var _world: Node = get_node_or_null("/root/World")

func _ready() -> void:
	_warehouse_btn.pressed.connect(_toggle_warehouse_panel)
	_targets_btn.pressed.connect(_toggle_targets_panel)
	_workers_btn.pressed.connect(_toggle_worker_management)
	mill_btn.pressed.connect(_on_mill_pressed)
	hire_worker_btn.pressed.connect(_on_hire_pressed)
	upgrade_house_btn.pressed.connect(_upgrade_house)
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	_warehouse_close_btn.pressed.connect(_close_warehouse_panel)
	_targets_close_btn.pressed.connect(_close_targets_panel)
	_worker_manage_close_btn.pressed.connect(_close_worker_management)
	_worker_manage_apply_btn.pressed.connect(_apply_worker_assignment)
	_worker_manage_reset_btn.pressed.connect(_reset_worker_assignment)
	_worker_manage_mode.item_selected.connect(_on_worker_mode_changed)
	_worker_manage_role.item_selected.connect(_on_worker_role_changed)
	_shop_close_btn.pressed.connect(_close_shop)
	_worker_close_btn.pressed.connect(_close_worker_panel)
	_upgrade_close_btn.pressed.connect(_close_upgrade_panel)
	_sell_list.action_selected.connect(_sell_item)
	_seed_blueprint_list.action_selected.connect(_buy_blueprint)
	_building_blueprint_list.action_selected.connect(_buy_blueprint)
	_animal_list.action_selected.connect(_on_buy_animal_pressed)

	_setup_top_bar()
	_setup_dynamic_lists()
	_setup_target_controls()
	_setup_worker_management_controls()
	warehouse_panel.position.x = 380.0

	if not InventoryManager.resources_updated.is_connected(_on_resources_updated):
		InventoryManager.resources_updated.connect(_on_resources_updated)
	if not InventoryManager.targets_updated.is_connected(_on_targets_updated):
		InventoryManager.targets_updated.connect(_on_targets_updated)
	_on_resources_updated()

func _setup_top_bar() -> void:
	for child in _resources_container.get_children():
		child.queue_free()

	var money_resource: ResourceItemComponent = ResourceItemScene.instantiate()
	money_resource.configure("res://assets/sprites/coin_final.png", "Coins: 0")
	money_resource.bind_money()
	_resources_container.add_child(money_resource)

func _setup_dynamic_lists() -> void:
	_warehouse_resource_list.repopulate()
	_sell_list.repopulate()
	_seed_blueprint_list.repopulate()
	_building_blueprint_list.repopulate()
	_animal_list.repopulate()
	sell_buttons = _sell_list.get_buttons()
	animal_buttons = _animal_list.get_buttons()
	blueprint_buttons = {}
	blueprint_buttons.merge(_seed_blueprint_list.get_buttons(), true)
	blueprint_buttons.merge(_building_blueprint_list.get_buttons(), true)

func _setup_target_controls() -> void:
	for child in _target_list.get_children():
		child.queue_free()
	_target_controls.clear()

	for item_type in GameData.get_targetable_item_order():
		var item_def: ItemDefinition = GameData.get_item_def(item_type)
		if item_def == null:
			continue
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = item_def.label
		icon.texture = ResourceLoader.load(item_def.icon_path)

		var stock_label := Label.new()
		stock_label.text = "0 / 0"
		stock_label.custom_minimum_size = Vector2(90, 0)
		stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		var spinbox := SpinBox.new()
		spinbox.min_value = 0
		spinbox.max_value = 999
		spinbox.step = 1
		spinbox.rounded = true
		spinbox.custom_minimum_size = Vector2(90, 0)
		spinbox.value_changed.connect(_on_target_value_changed.bind(item_type))

		row.add_child(icon)
		row.add_child(stock_label)
		row.add_child(spinbox)
		_target_list.add_child(row)
		_target_controls[item_type] = {
			"stock_label": stock_label,
			"spinbox": spinbox,
		}

	_on_targets_updated()

func _setup_worker_management_controls() -> void:
	_worker_manage_info_label.text = "Workers now act automatically by house.\nUse the Targets panel to set stock goals when you want them to focus production."
	for node in [_worker_manage_mode_label, _worker_manage_mode, _worker_manage_role_label, _worker_manage_role, _worker_manage_target_label, _worker_manage_target, _worker_manage_fallback, _worker_manage_apply_btn, _worker_manage_reset_btn]:
		node.visible = false
	_refresh_worker_management_panel()
	_refresh_worker_house_panel()

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
		targets_panel.visible = false
		worker_panel.visible = false
		worker_manage_panel.visible = false
		_close_warehouse_panel(false)
		_on_resources_updated()

func _on_upgrade_pressed() -> void:
	if FarmManager.upgrade_tile(current_upgrade_cell):
		_on_resources_updated()

func toggle_shop() -> void:
	shop_panel.visible = not shop_panel.visible
	if shop_panel.visible:
		targets_panel.visible = false
		worker_panel.visible = false
		worker_manage_panel.visible = false
		upgrade_panel.visible = false
		_close_warehouse_panel(false)

func toggle_worker_house(domain_id: String = GameData.WORKER_DOMAIN_FARM) -> void:
	var switched_domain: bool = _current_worker_house_domain != domain_id
	_current_worker_house_domain = domain_id
	_refresh_worker_house_panel()
	if switched_domain and worker_panel.visible:
		shop_panel.visible = false
		targets_panel.visible = false
		worker_manage_panel.visible = false
		upgrade_panel.visible = false
		_close_warehouse_panel(false)
		return
	worker_panel.visible = not worker_panel.visible
	if worker_panel.visible:
		shop_panel.visible = false
		targets_panel.visible = false
		worker_manage_panel.visible = false
		upgrade_panel.visible = false
		_close_warehouse_panel(false)

func _toggle_warehouse_panel() -> void:
	if warehouse_panel.visible:
		_close_warehouse_panel()
	else:
		_open_warehouse_panel()

func _open_warehouse_panel() -> void:
	_warehouse_resource_list.repopulate()
	shop_panel.visible = false
	targets_panel.visible = false
	worker_panel.visible = false
	worker_manage_panel.visible = false
	upgrade_panel.visible = false
	warehouse_panel.visible = true
	warehouse_panel.position.x = 380.0
	_animate_warehouse_to(0.0)

func _close_warehouse_panel(animate: bool = true) -> void:
	if not warehouse_panel.visible and not animate:
		return
	if animate:
		_animate_warehouse_to(380.0, true)
	else:
		warehouse_panel.visible = false
		warehouse_panel.position.x = 380.0

func _animate_warehouse_to(target_x: float, hide_after: bool = false) -> void:
	_hide_warehouse_after_tween = hide_after
	if _warehouse_tween and _warehouse_tween.is_valid():
		_warehouse_tween.kill()
	_warehouse_tween = create_tween()
	_warehouse_tween.tween_property(warehouse_panel, "position:x", target_x, 0.18)
	_warehouse_tween.finished.connect(_on_warehouse_tween_finished)

func _on_warehouse_tween_finished() -> void:
	if _hide_warehouse_after_tween:
		warehouse_panel.visible = false
		warehouse_panel.position.x = 380.0
	_hide_warehouse_after_tween = false

func _toggle_targets_panel() -> void:
	if targets_panel.visible:
		_close_targets_panel()
	else:
		_open_targets_panel()

func _open_targets_panel() -> void:
	shop_panel.visible = false
	worker_panel.visible = false
	worker_manage_panel.visible = false
	upgrade_panel.visible = false
	_close_warehouse_panel(false)
	targets_panel.visible = true
	_on_targets_updated()

func _close_targets_panel() -> void:
	targets_panel.visible = false

func _toggle_worker_management() -> void:
	if worker_manage_panel.visible:
		_close_worker_management()
	else:
		_open_worker_management()

func _open_worker_management() -> void:
	shop_panel.visible = false
	targets_panel.visible = false
	worker_panel.visible = false
	upgrade_panel.visible = false
	_close_warehouse_panel(false)
	worker_manage_panel.visible = true
	_refresh_worker_management_panel()

func _close_worker_management() -> void:
	worker_manage_panel.visible = false

func _refresh_worker_management_panel() -> void:
	var workers: Array[FarmWorker] = _get_workers_sorted()
	for child in _worker_manage_list.get_children():
		child.queue_free()
	worker_assignment_buttons.clear()

	for worker in workers:
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = _get_worker_panel_button_text(worker)
		btn.pressed.connect(_select_worker.bind(worker))
		_worker_manage_list.add_child(btn)
		worker_assignment_buttons[worker.worker_id] = btn

	if workers.is_empty():
		_selected_worker = null
		_update_worker_assignment_editor()
		return

	if _selected_worker == null or not is_instance_valid(_selected_worker) or not workers.has(_selected_worker):
		_selected_worker = workers[0]
	_update_worker_assignment_editor()

func _refresh_worker_management_statuses() -> void:
	var workers: Array[FarmWorker] = _get_workers_sorted()
	if workers.is_empty():
		_selected_worker = null
		_update_worker_assignment_editor()
		return

	for worker in workers:
		var btn: Button = worker_assignment_buttons.get(worker.worker_id, null)
		if btn != null:
			btn.text = _get_worker_panel_button_text(worker)

	if _selected_worker == null or not is_instance_valid(_selected_worker) or not workers.has(_selected_worker):
		_selected_worker = workers[0]
	_update_worker_assignment_editor(false)

func _get_worker_panel_button_text(worker: FarmWorker) -> String:
	return "%s\n%s\nStatus: %s" % [worker.get_display_name(), worker.get_assignment_summary(), worker.get_current_status()]

func _select_worker(worker: FarmWorker) -> void:
	_selected_worker = worker
	_update_worker_assignment_editor()

func _update_worker_assignment_editor(_refresh_options: bool = true) -> void:
	for worker_id in worker_assignment_buttons.keys():
		var btn: Button = worker_assignment_buttons[worker_id]
		btn.disabled = false

	if _selected_worker == null or not is_instance_valid(_selected_worker) or _selected_worker.get_parent() == null:
		_selected_worker = null
		_worker_manage_selected_label.text = "No worker selected"
		return

	var selected_button: Button = worker_assignment_buttons.get(_selected_worker.worker_id, null)
	if selected_button != null:
		selected_button.disabled = true

	_worker_manage_selected_label.text = "%s\n%s\n%s" % [_selected_worker.get_display_name(), _selected_worker.get_assignment_summary(), _selected_worker.get_current_status()]
	_update_worker_assignment_editor_state()

func _populate_option_button(button: OptionButton, options: Array[Dictionary], selected_id: String) -> void:
	button.clear()
	var selected_index := 0
	for option in options:
		var idx: int = button.get_item_count()
		button.add_item(String(option.get("label", "Option")))
		button.set_item_metadata(idx, String(option.get("id", "")))
		if String(option.get("id", "")) == selected_id:
			selected_index = idx
	button.select(selected_index)

func _refresh_worker_target_options(selected_target_id: String, from_role_change: bool) -> void:
	var role_id: String = _get_selected_option_metadata(_worker_manage_role)
	if _selected_worker != null and is_instance_valid(_selected_worker):
		if not GameData.is_worker_role_allowed_for_domain(_selected_worker.get_worker_domain(), role_id):
			role_id = GameData.get_default_worker_role_for_domain(_selected_worker.get_worker_domain())
	var options: Array[Dictionary] = GameData.get_worker_target_options(role_id)
	var target_id := selected_target_id
	if from_role_change and not options.is_empty():
		target_id = String(options[0].get("id", ""))
	_populate_option_button(_worker_manage_target, options, target_id)
	_update_worker_assignment_editor_state()

func _get_selected_option_metadata(button: OptionButton) -> String:
	var idx := button.selected
	if idx < 0:
		return ""
	return String(button.get_item_metadata(idx))

func _on_worker_mode_changed(_index: int) -> void:
	_update_worker_assignment_editor_state()

func _on_worker_role_changed(_index: int) -> void:
	_refresh_worker_target_options("", true)

func _update_worker_assignment_editor_state() -> void:
	return

func _apply_worker_assignment() -> void:
	return

func _reset_worker_assignment() -> void:
	return

func _get_workers_sorted() -> Array[FarmWorker]:
	var result: Array[FarmWorker] = []
	for worker in get_tree().get_nodes_in_group("workers"):
		if worker is FarmWorker and is_instance_valid(worker):
			result.append(worker)
	result.sort_custom(_sort_workers_by_id)
	return result

func _on_hire_pressed() -> void:
	if InventoryManager.buy_worker(_current_worker_house_domain):
		if _world == null:
			_world = get_node_or_null("/root/World")
		if _world:
			_world._spawn_worker(_current_worker_house_domain)
		_refresh_worker_house_panel()
		_refresh_worker_management_panel()

func _refresh_worker_house_panel() -> void:
	var domain_label: String = GameData.get_worker_domain_label(_current_worker_house_domain)
	_worker_panel_title.text = "--- %s ---" % domain_label.to_upper()
	var domain_worker_count: int = InventoryManager.get_worker_count(_current_worker_house_domain)
	var worker_price: int = InventoryManager.get_worker_price()
	hire_worker_btn.text = "Hire %s (%d/%d)\n-%d Coins" % [
		domain_label.replace(" House", ""),
		domain_worker_count,
		InventoryManager.get_max_workers(),
		worker_price,
	]
	hire_worker_btn.disabled = InventoryManager.count_workers_bought >= InventoryManager.get_max_workers() or InventoryManager.money < worker_price
	var house_price: int = InventoryManager.get_house_upgrade_price()
	if InventoryManager.house_level < GameData.MAX_UPGRADE_LEVEL:
		upgrade_house_btn.text = "Upgrade Housing (Lv %d)\n-%d Coins" % [InventoryManager.house_level, house_price]
		upgrade_house_btn.disabled = InventoryManager.money < house_price
	else:
		upgrade_house_btn.text = "Upgrade Housing (MAX Lv %d)" % GameData.MAX_UPGRADE_LEVEL
		upgrade_house_btn.disabled = true

func _on_target_value_changed(value: float, item_type: String) -> void:
	InventoryManager.set_item_target(item_type, int(value))

func _on_targets_updated() -> void:
	for item_type in _target_controls.keys():
		var controls: Dictionary = _target_controls[item_type]
		var stock_label: Label = controls.get("stock_label", null)
		var spinbox: SpinBox = controls.get("spinbox", null)
		if stock_label != null:
			stock_label.text = "%d / %d" % [InventoryManager.get_item_stock(item_type), InventoryManager.get_item_target(item_type)]
			if InventoryManager.is_item_below_target(item_type):
				stock_label.modulate = Color(1.0, 0.8, 0.35, 1.0)
			else:
				stock_label.modulate = Color(0.8, 1.0, 0.8, 1.0)
		if spinbox != null and int(spinbox.value) != InventoryManager.get_item_target(item_type):
			spinbox.value = InventoryManager.get_item_target(item_type)

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
	var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
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
	_refresh_worker_house_panel()
	_on_targets_updated()

	mill_btn.text = "Mill: PAUSED" if InventoryManager.mill_paused else "Mill: ON"

	if upgrade_panel.visible:
		_update_upgrade_panel_info()

	for item_type in sell_buttons.keys():
		var sell_button: Button = sell_buttons[item_type]
		var item_def: ItemDefinition = GameData.get_item_def(item_type)
		var sell_label: String = item_type
		var sell_price: int = 0
		if item_def != null:
			sell_label = item_def.label
			sell_price = item_def.sell_price
		sell_button.text = "Sell %s (+%d Coin%s)" % [sell_label, sell_price, "" if sell_price == 1 else "s"]
		sell_button.disabled = InventoryManager.get_item_stock(item_type) < 1

	for blueprint_type in blueprint_buttons.keys():
		var blueprint_button: Button = blueprint_buttons[blueprint_type]
		var blueprint_def: BlueprintDefinition = GameData.get_blueprint_def(blueprint_type)
		if blueprint_def == null:
			blueprint_button.text = blueprint_type
			blueprint_button.disabled = true
			continue
		blueprint_button.text = _format_blueprint_cost_text(blueprint_def)
		blueprint_button.disabled = not _can_afford_blueprint(blueprint_def)

	if worker_manage_panel.visible:
		_refresh_worker_management_statuses()

	if _world == null:
		_world = get_node_or_null("/root/World")
	for animal_type in animal_buttons.keys():
		var animal_button: Button = animal_buttons[animal_type]
		var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
		if animal_def == null:
			continue
		var pen_type: String = animal_def.pen_blueprint_type
		var price: int = animal_def.price
		var label: String = animal_def.label
		var pen_def: BlueprintDefinition = GameData.get_blueprint_def(pen_type)
		var pen_label: String = pen_type
		if pen_def != null:
			pen_label = pen_def.label
		if _world and _world.has_empty_pen(pen_type):
			animal_button.text = "Buy %s (-%d Coins)" % [label, price]
			animal_button.disabled = InventoryManager.money < price
		else:
			animal_button.text = "Buy %s (Need %s!)" % [label, pen_label]
			animal_button.disabled = true

func _format_blueprint_cost_text(blueprint_def: BlueprintDefinition) -> String:
	var parts: Array[String] = ["-%d Coins" % InventoryManager.get_blueprint_price(blueprint_def.blueprint_id)]
	for cost in blueprint_def.resource_costs:
		if cost == null or cost.item_def == null:
			continue
		parts.append("-%d %s" % [int(cost.amount), cost.item_def.label])
	return "%s (%s)" % [blueprint_def.label, ", ".join(parts)]

func _can_afford_blueprint(blueprint_def: BlueprintDefinition) -> bool:
	if InventoryManager.money < InventoryManager.get_blueprint_price(blueprint_def.blueprint_id):
		return false
	return InventoryManager.has_resource_costs(blueprint_def.resource_costs)

func _update_upgrade_panel_info() -> void:
	var lvl: int = FarmManager.get_tile_level(current_upgrade_cell)
	var type_str: String = "Plot"
	var effect_str: String = "Yield: %d -> %d" % [lvl, lvl + 1]

	var real_state = FarmManager.get_tile_state(current_upgrade_cell)
	if real_state == FarmManager.TileState.PROCESSOR:
		var processor_def: ProcessorDefinition = GameData.get_processor_def(FarmManager.get_processor_type(current_upgrade_cell))
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

func _sort_workers_by_id(a: FarmWorker, b: FarmWorker) -> bool:
	return a.worker_id < b.worker_id
