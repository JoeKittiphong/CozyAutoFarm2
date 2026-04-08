extends PanelContainer
class_name ShopPanelController

const SHOP_TAB_SHOP := "shop"
const SHOP_TAB_SEEDS := "seeds"
const SHOP_TAB_BUILDINGS := "buildings"
const SHOP_TAB_ANIMALS := "animals"

signal closed

var sell_buttons: Dictionary = {}
var animal_buttons: Dictionary = {}
var blueprint_buttons: Dictionary = {}
var _current_shop_tab: String = SHOP_TAB_SHOP
var _world: Node = null

@onready var _sell_list: GameActionListComponent = $Content/ScrollContainer/ScrollContent/SellList
@onready var _seed_blueprint_list: GameActionListComponent = get_node_or_null("Content/ScrollContainer/ScrollContent/SeedBlueprintList")
@onready var _building_blueprint_list: GameActionListComponent = $Content/ScrollContainer/ScrollContent/BuildingBlueprintList
@onready var _animal_list: GameActionListComponent = $Content/ScrollContainer/ScrollContent/AnimalList
@onready var _shop_title: Label = get_node_or_null("Content/Title")
@onready var _shop_tab_btn: Button = $Content/CategoryTabs/ShopTabButton
@onready var _seed_tab_btn: Button = get_node_or_null("Content/CategoryTabs/SeedTabButton")
@onready var _building_tab_btn: Button = $Content/CategoryTabs/BuildingTabButton
@onready var _animal_tab_btn: Button = $Content/CategoryTabs/AnimalTabButton
@onready var _seed_title: Label = get_node_or_null("Content/ScrollContainer/ScrollContent/SeedTitle")
@onready var _building_title: Label = $Content/ScrollContainer/ScrollContent/BuildingTitle
@onready var _animal_title: Label = $Content/ScrollContainer/ScrollContent/AnimalTitle
@onready var _close_btn: Button = $Content/CloseButton

func _ready() -> void:
	_close_btn.pressed.connect(_close_panel)
	_sell_list.action_selected.connect(_sell_item)
	if _seed_blueprint_list != null:
		_seed_blueprint_list.action_selected.connect(_buy_blueprint)
	_seed_blueprint_list.visible = false if _seed_blueprint_list != null else false
	_building_blueprint_list.action_selected.connect(_buy_blueprint)
	_animal_list.action_selected.connect(_on_buy_animal_pressed)
	_shop_tab_btn.pressed.connect(_set_shop_tab.bind(SHOP_TAB_SHOP))
	if _seed_tab_btn != null:
		_seed_tab_btn.visible = false
	_building_tab_btn.pressed.connect(_set_shop_tab.bind(SHOP_TAB_BUILDINGS))
	_animal_tab_btn.pressed.connect(_set_shop_tab.bind(SHOP_TAB_ANIMALS))
	_setup_dynamic_lists()
	_refresh_shop_tab_ui()

func set_world(world: Node) -> void:
	_world = world

func refresh_resources() -> void:
	for item_type in sell_buttons.keys():
		var sell_button: ActionButtonComponent = sell_buttons[item_type]
		var item_def: ItemDefinition = GameData.get_item_def(item_type)
		var sell_label: String = item_type
		var sell_price: int = 0
		var icon_texture: Texture2D = null
		var stock: int = InventoryManager.get_item_stock(item_type)
		if item_def != null:
			sell_label = item_def.label
			sell_price = item_def.sell_price
			if item_def.icon_path != "":
				icon_texture = ResourceLoader.load(item_def.icon_path)
		sell_button.set_card_content(icon_texture, sell_label, "+%d" % sell_price)
		sell_button.set_badge_text(str(stock))
		sell_button.disabled = stock < 1

	for blueprint_type in blueprint_buttons.keys():
		var blueprint_button: ActionButtonComponent = blueprint_buttons[blueprint_type]
		var blueprint_def: BlueprintDefinition = GameData.get_blueprint_def(blueprint_type)
		if blueprint_def == null:
			blueprint_button.set_card_content(null, blueprint_type, "")
			blueprint_button.set_badge_text("")
			blueprint_button.disabled = true
			continue
		blueprint_button.set_card_content(_get_blueprint_shop_icon(blueprint_def), blueprint_def.label, "-%d" % InventoryManager.get_blueprint_price(blueprint_def.blueprint_id))
		blueprint_button.set_badge_text("")
		blueprint_button.tooltip_text = _format_blueprint_cost_text(blueprint_def)
		blueprint_button.disabled = not _can_afford_blueprint(blueprint_def)

	for animal_type in animal_buttons.keys():
		var animal_button: ActionButtonComponent = animal_buttons[animal_type]
		var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
		if animal_def == null:
			continue
		var pen_type: String = animal_def.pen_blueprint_type
		var price: int = animal_def.price
		var label: String = animal_def.label
		var icon_texture: Texture2D = null
		if animal_def.icon_path != "":
			icon_texture = ResourceLoader.load(animal_def.icon_path)
		var pen_def: BlueprintDefinition = GameData.get_blueprint_def(pen_type)
		var pen_label: String = pen_type
		if pen_def != null:
			pen_label = pen_def.label
		animal_button.set_card_content(icon_texture, label, "-%d" % price)
		animal_button.set_badge_text("")
		if _world and _world.has_empty_pen(pen_type):
			animal_button.tooltip_text = "Buy %s (-%d Coins)" % [label, price]
			animal_button.disabled = InventoryManager.money < price
		else:
			animal_button.tooltip_text = "Buy %s (Need %s!)" % [label, pen_label]
			animal_button.disabled = true

func open_panel() -> void:
	visible = true
	_refresh_shop_tab_ui()

func close_panel() -> void:
	visible = false

func toggle_panel() -> void:
	visible = not visible
	if visible:
		_refresh_shop_tab_ui()

func _close_panel() -> void:
	visible = false
	closed.emit()

func _setup_dynamic_lists() -> void:
	_sell_list.repopulate()
	_building_blueprint_list.repopulate()
	_animal_list.repopulate()
	sell_buttons = _sell_list.get_buttons()
	animal_buttons = _animal_list.get_buttons()
	blueprint_buttons = {}
	blueprint_buttons.merge(_building_blueprint_list.get_buttons(), true)

func _set_shop_tab(tab_id: String) -> void:
	if tab_id == SHOP_TAB_SEEDS:
		tab_id = SHOP_TAB_BUILDINGS
	_current_shop_tab = tab_id
	_refresh_shop_tab_ui()

func _refresh_shop_tab_ui() -> void:
	var tab_titles: Dictionary = {
		SHOP_TAB_SHOP: "--- SHOP ---",
		SHOP_TAB_BUILDINGS: "--- BUILDINGS ---",
		SHOP_TAB_ANIMALS: "--- ANIMALS ---",
	}
	if _shop_title != null:
		_shop_title.text = String(tab_titles.get(_current_shop_tab, "--- SHOP ---"))

	var sell_visible: bool = _current_shop_tab == SHOP_TAB_SHOP
	var building_visible: bool = _current_shop_tab == SHOP_TAB_BUILDINGS
	var animal_visible: bool = _current_shop_tab == SHOP_TAB_ANIMALS

	_sell_list.visible = sell_visible
	if _seed_title != null:
		_seed_title.visible = false
	if _seed_blueprint_list != null:
		_seed_blueprint_list.visible = false
	_building_title.visible = false
	_building_blueprint_list.visible = building_visible
	_animal_title.visible = false
	_animal_list.visible = animal_visible

	_shop_tab_btn.disabled = sell_visible
	_building_tab_btn.disabled = building_visible
	_animal_tab_btn.disabled = animal_visible

func _sell_item(item_type: String) -> void:
	InventoryManager.sell_item(item_type)

func _buy_blueprint(blueprint_type: String) -> void:
	InventoryManager.buy_blueprint(blueprint_type)

func _on_buy_animal_pressed(animal_type: String) -> void:
	var animal_def: AnimalDefinition = GameData.get_animal_def(animal_type)
	if animal_def == null:
		return
	if _world and _world.has_empty_pen(animal_def.pen_blueprint_type):
		if InventoryManager.spend_money(animal_def.price):
			_world._spawn_animal_at_shop(animal_type)

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

func _get_blueprint_shop_icon(blueprint_def: BlueprintDefinition) -> Texture2D:
	if blueprint_def == null:
		return null
	if blueprint_def.texture_path != "":
		return ResourceLoader.load(blueprint_def.texture_path)
	var item_def: ItemDefinition = GameData.get_item_def(blueprint_def.blueprint_id)
	if item_def != null and item_def.icon_path != "":
		return ResourceLoader.load(item_def.icon_path)
	if blueprint_def.crop_type != "":
		var crop_item_def: ItemDefinition = GameData.get_item_def(blueprint_def.crop_type)
		if crop_item_def != null and crop_item_def.icon_path != "":
			return ResourceLoader.load(crop_item_def.icon_path)
	return null
