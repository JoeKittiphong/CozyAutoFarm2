extends CanvasLayer

var money_label: Label
var wheat_label: Label
var flour_label: Label
var egg_label: Label
var milk_label: Label
var cake_label: Label
var mill_btn: Button

# Popups
var shop_panel: PanelContainer
var worker_panel: PanelContainer

# Blueprint Buttons
var hire_worker_btn: Button
var buy_wheat_btn: Button
var buy_tomato_btn: Button
var buy_potato_btn: Button
var buy_coop_btn: Button
var buy_cow_pen_btn: Button
var buy_bakery_btn: Button
var buy_mill_btn: Button
var upgrade_house_btn: Button

var upgrade_panel: PanelContainer
var upgrade_info_label: Label
var upgrade_btn: Button
var current_upgrade_cell: Vector2i = Vector2i(-999, -999)
var buy_chicken_btn: Button
var buy_cow_btn: Button
var stock_info_label: Label
var tomato_label: Label
var potato_label: Label

func _ready() -> void:
    # 1. Top Bar
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
    wheat_label = _create_resource_ui(hbox, "res://assets/sprites/wheat_item.png", "Wheat: 0")
    tomato_label = _create_resource_ui(hbox, "res://assets/sprites/tomato_item.png", "Tomato: 0")
    potato_label = _create_resource_ui(hbox, "res://assets/sprites/potato_item.png", "Potato: 0")
    flour_label = _create_resource_ui(hbox, "res://assets/sprites/flour_bag.png", "Flour: 0")
    egg_label = _create_resource_ui(hbox, "res://assets/sprites/egg_item.png", "Eggs: 0")
    milk_label = _create_resource_ui(hbox, "res://assets/sprites/milk_bucket.png", "Milk: 0")
    cake_label = _create_resource_ui(hbox, "res://assets/sprites/cake_final.png", "Cake: 0")
    
    mill_btn = Button.new()
    mill_btn.text = "Mill: ON"
    mill_btn.pressed.connect(_on_mill_pressed)
    hbox.add_child(mill_btn)

    top_panel.add_child(hbox)
    add_child(top_panel)
    
    # 2. Setup Popups
    _setup_shop_ui()
    _setup_worker_ui()
    _setup_upgrade_ui()
    
    var inv = get_node_or_null("/root/InventoryManager")
    if inv:
        inv.resources_updated.connect(_on_resources_updated)
        _on_resources_updated()

func _create_resource_ui(parent: Node, icon_path: String, start_val: String) -> Label:
    var bx = HBoxContainer.new()
    var tex = TextureRect.new()
    tex.texture = load(icon_path)
    tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH
    tex.custom_minimum_size = Vector2(24, 24)
    tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var lbl = Label.new()
    lbl.text = start_val
    lbl.add_theme_font_size_override("font_size", 14)
    bx.add_child(tex)
    bx.add_child(lbl)
    parent.add_child(bx)
    return lbl

func _setup_shop_ui():
    shop_panel = PanelContainer.new()
    shop_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_MINSIZE, 0)
    shop_panel.offset_top = 40
    shop_panel.custom_minimum_size.x = 350
    shop_panel.visible = false
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.15, 0.1, 0.95)
    style.border_width_bottom = 4
    style.border_width_top = 4
    style.border_width_left = 4
    style.border_width_right = 4
    style.border_color = Color(0.8, 0.6, 0.2)
    style.corner_radius_bottom_right = 10
    style.corner_radius_top_right = 10
    shop_panel.add_theme_stylebox_override("panel", style)
    
    var vbox = VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
    vbox.add_theme_constant_override("separation", 15)
    
    # Add top margin
    var spacer = Control.new()
    spacer.custom_minimum_size.y = 20
    vbox.add_child(spacer)
    
    var title = Label.new()
    title.text = "--- SHOP ---"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)
    
    var sell_wheat = Button.new()
    sell_wheat.text = "Sell Wheat (+1 Coin)"
    sell_wheat.pressed.connect(func(): get_node("/root/InventoryManager").sell_item("WHEAT"))
    vbox.add_child(sell_wheat)

    var sell_tomato = Button.new()
    sell_tomato.text = "Sell Tomato (+1 Coin)"
    sell_tomato.pressed.connect(func(): get_node("/root/InventoryManager").sell_item("TOMATO"))
    vbox.add_child(sell_tomato)

    var sell_potato = Button.new()
    sell_potato.text = "Sell Potato (+1 Coin)"
    sell_potato.pressed.connect(func(): get_node("/root/InventoryManager").sell_item("POTATO"))
    vbox.add_child(sell_potato)

    var sell_flour = Button.new()
    sell_flour.text = "Sell Flour (+4 Coins)"
    sell_flour.pressed.connect(func(): get_node("/root/InventoryManager").sell_item("FLOUR"))
    vbox.add_child(sell_flour)

    var sell_egg = Button.new()
    sell_egg.text = "Sell Egg (+5 Coins)"
    sell_egg.pressed.connect(func(): get_node("/root/InventoryManager").sell_item("EGG"))
    vbox.add_child(sell_egg)

    var sell_milk = Button.new()
    sell_milk.text = "Sell Milk (+7 Coins)"
    sell_milk.pressed.connect(func(): get_node("/root/InventoryManager").sell_item("MILK"))
    vbox.add_child(sell_milk)

    var sell_cake = Button.new()
    sell_cake.text = "Sell Cake (+25 Coins)"
    sell_cake.pressed.connect(func(): get_node("/root/InventoryManager").sell_item("CAKE"))
    vbox.add_child(sell_cake)
    
    buy_chicken_btn = Button.new()
    buy_chicken_btn.text = "Buy Chicken (-20 Coins)"
    buy_chicken_btn.pressed.connect(_on_buy_chicken_pressed)
    vbox.add_child(buy_chicken_btn)
    
    buy_cow_btn = Button.new()
    buy_cow_btn.text = "Buy Cow (-40 Coins)"
    buy_cow_btn.pressed.connect(_on_buy_cow_pressed)
    vbox.add_child(buy_cow_btn)
    
    var close_btn = Button.new()
    close_btn.text = "Close"
    close_btn.pressed.connect(func(): shop_panel.visible = false)
    vbox.add_child(close_btn)
    
    shop_panel.add_child(vbox)
    add_child(shop_panel)

func _setup_worker_ui():
    worker_panel = PanelContainer.new()
    worker_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_MINSIZE, 0)
    worker_panel.offset_top = 40
    worker_panel.custom_minimum_size.x = 350
    worker_panel.visible = false
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.15, 0.2, 0.1, 0.95)
    style.border_width_bottom = 4
    style.border_width_top = 4
    style.border_width_left = 4
    style.border_width_right = 4
    style.border_color = Color(0.4, 0.8, 0.2)
    style.corner_radius_bottom_right = 10
    style.corner_radius_top_right = 10
    worker_panel.add_theme_stylebox_override("panel", style)
    
    var vbox = VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
    vbox.add_theme_constant_override("separation", 15)
    
    # Add top margin
    var spacer = Control.new()
    spacer.custom_minimum_size.y = 20
    vbox.add_child(spacer)
    
    var title = Label.new()
    title.text = "--- WORKER HOUSE ---"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)
    
    hire_worker_btn = Button.new()
    hire_worker_btn.pressed.connect(_on_hire_pressed)
    vbox.add_child(hire_worker_btn)
    
    upgrade_house_btn = Button.new()
    upgrade_house_btn.pressed.connect(func(): get_node("/root/InventoryManager").upgrade_house())
    vbox.add_child(upgrade_house_btn)
    
    var title2 = Label.new()
    title2.text = "--- BUY BLUEPRINTS ---"
    title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title2)
    
    buy_wheat_btn = Button.new()
    buy_wheat_btn.pressed.connect(func(): get_node("/root/InventoryManager").buy_blueprint("WHEAT"))
    vbox.add_child(buy_wheat_btn)

    buy_tomato_btn = Button.new()
    buy_tomato_btn.pressed.connect(func(): get_node("/root/InventoryManager").buy_blueprint("TOMATO"))
    vbox.add_child(buy_tomato_btn)

    buy_potato_btn = Button.new()
    buy_potato_btn.pressed.connect(func(): get_node("/root/InventoryManager").buy_blueprint("POTATO"))
    vbox.add_child(buy_potato_btn)
    
    buy_coop_btn = Button.new()
    buy_coop_btn.pressed.connect(func(): get_node("/root/InventoryManager").buy_blueprint("COOP"))
    vbox.add_child(buy_coop_btn)
    
    buy_cow_pen_btn = Button.new()
    buy_cow_pen_btn.pressed.connect(func(): get_node("/root/InventoryManager").buy_blueprint("COW_PEN"))
    vbox.add_child(buy_cow_pen_btn)

    buy_bakery_btn = Button.new()
    buy_bakery_btn.pressed.connect(func(): get_node("/root/InventoryManager").buy_blueprint("BAKERY"))
    vbox.add_child(buy_bakery_btn)
    
    buy_mill_btn = Button.new()
    buy_mill_btn.pressed.connect(func(): get_node("/root/InventoryManager").buy_blueprint("MILL"))
    vbox.add_child(buy_mill_btn)
    
    stock_info_label = Label.new()
    stock_info_label.text = "Stock: "
    stock_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stock_info_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
    vbox.add_child(stock_info_label)

    var close_btn = Button.new()
    close_btn.text = "Close"
    close_btn.pressed.connect(func(): worker_panel.visible = false)
    vbox.add_child(close_btn)
    
    worker_panel.add_child(vbox)
    add_child(worker_panel)

func _setup_upgrade_ui():
    upgrade_panel = PanelContainer.new()
    # Align to left sidebar, same as shop/worker
    upgrade_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_MINSIZE, 0)
    upgrade_panel.offset_top = 40
    upgrade_panel.custom_minimum_size.x = 350
    upgrade_panel.visible = false
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.05, 0.15, 0.1, 0.95)
    style.border_width_top = 4
    style.border_width_right = 4
    style.border_color = Color(0.2, 0.9, 0.5)
    style.corner_radius_bottom_right = 12
    style.corner_radius_top_right = 12
    upgrade_panel.add_theme_stylebox_override("panel", style)
    
    var vbox = VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
    vbox.add_theme_constant_override("separation", 15)
    
    # Add top margin
    var spacer = Control.new()
    spacer.custom_minimum_size.y = 20
    vbox.add_child(spacer)
    
    var title = Label.new()
    title.text = "--- UPGRADE ---"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
    vbox.add_child(title)
    
    upgrade_info_label = Label.new()
    upgrade_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(upgrade_info_label)
    
    upgrade_btn = Button.new()
    upgrade_btn.custom_minimum_size = Vector2(0, 50)
    upgrade_btn.text = "Upgrade"
    upgrade_btn.pressed.connect(_on_upgrade_pressed)
    vbox.add_child(upgrade_btn)
    
    var close_btn = Button.new()
    close_btn.custom_minimum_size = Vector2(0, 50)
    close_btn.text = "Close"
    close_btn.pressed.connect(func(): upgrade_panel.visible = false)
    vbox.add_child(close_btn)
    
    upgrade_panel.add_child(vbox)
    add_child(upgrade_panel)

func open_upgrade_ui(cell: Vector2i):
    var f_manager = get_node("/root/FarmManager")
    var state = f_manager.get_tile_state(cell)
    
    # Only upgrade buildings or plots that are past blueprint stage
    var valid_states = [
        f_manager.TileState.TILLED, f_manager.TileState.PLANTED, f_manager.TileState.WATERED,
        f_manager.TileState.GROWING, f_manager.TileState.READY_TO_HARVEST,
        f_manager.TileState.TOMATO_SPROUT, f_manager.TileState.TOMATO_READY,
        f_manager.TileState.POTATO_SPROUT, f_manager.TileState.POTATO_READY,
        f_manager.TileState.BAKERY, f_manager.TileState.MILL,
        f_manager.TileState.COOP, f_manager.TileState.COW_PEN
    ]
    
    if state in valid_states:
        current_upgrade_cell = cell
        upgrade_panel.visible = true
        shop_panel.visible = false
        worker_panel.visible = false
        _on_resources_updated()

func _on_upgrade_pressed():
    var f_manager = get_node("/root/FarmManager")
    if f_manager.upgrade_tile(current_upgrade_cell):
        _on_resources_updated()

func toggle_shop():
    shop_panel.visible = not shop_panel.visible
    if shop_panel.visible:
        worker_panel.visible = false
        upgrade_panel.visible = false

func toggle_worker_house():
    worker_panel.visible = not worker_panel.visible
    if worker_panel.visible:
        shop_panel.visible = false
        upgrade_panel.visible = false

func _on_hire_pressed() -> void:
    var inv = get_node("/root/InventoryManager")
    if inv.buy_worker():
        var world = get_node_or_null("/root/World")
        if world:
            world._spawn_worker()

func _on_buy_chicken_pressed() -> void:
    var world = get_node_or_null("/root/World")
    if world and world.has_empty_pen("COOP"):
        var inv = get_node("/root/InventoryManager")
        if inv.spend_money(20):
            world._spawn_animal_at_shop("CHICKEN")

func _on_buy_cow_pressed() -> void:
    var world = get_node_or_null("/root/World")
    if world and world.has_empty_pen("COW_PEN"):
        var inv = get_node("/root/InventoryManager")
        if inv.spend_money(40):
            world._spawn_animal_at_shop("COW")

func _on_mill_pressed() -> void:
    var inv = get_node("/root/InventoryManager")
    inv.mill_paused = not inv.mill_paused
    if inv.mill_paused:
        mill_btn.text = "Mill: PAUSED"
    else:
        mill_btn.text = "Mill: ON"

func _on_resources_updated() -> void:
    var inv = get_node("/root/InventoryManager")
    money_label.text = "Coins: " + str(inv.money)
    wheat_label.text = "Wheat: " + str(inv.wheat_stock)
    flour_label.text = "Flour: " + str(inv.flour_stock)
    egg_label.text = "Eggs: " + str(inv.egg_stock)
    milk_label.text = "Milk: " + str(inv.milk_stock)
    cake_label.text = "Cake: " + str(inv.cake_stock)
    
    if hire_worker_btn:
        hire_worker_btn.text = "Hire Worker (" + str(inv.count_workers_bought) + "/" + str(inv.get_max_workers()) + ")\n-" + str(inv.get_worker_price()) + " Coins"
        hire_worker_btn.disabled = inv.count_workers_bought >= inv.get_max_workers()
        
    if upgrade_house_btn:
        var hp = inv.get_house_upgrade_price()
        if inv.house_level < 5:
            upgrade_house_btn.text = "Upgrade House (Lv " + str(inv.house_level) + ")\n-" + str(hp) + " Coins"
            upgrade_house_btn.disabled = inv.money < hp
        else:
            upgrade_house_btn.text = "Upgrade House (MAX Lv 5)"
            upgrade_house_btn.disabled = true
            
    if upgrade_panel and upgrade_panel.visible:
        _update_upgrade_panel_info()
        
    if buy_wheat_btn:
        buy_wheat_btn.text = "Wheat Seeds (-" + str(inv.get_bp_price_wheat()) + " Coins)"
    if buy_tomato_btn:
        buy_tomato_btn.text = "Tomato Seeds (-" + str(inv.get_bp_price_tomato()) + " Coins)"
    if buy_potato_btn:
        buy_potato_btn.text = "Potato Seeds (-" + str(inv.get_bp_price_potato()) + " Coins)"
    if buy_coop_btn:
        buy_coop_btn.text = "Chicken Coop (-" + str(inv.get_bp_price_coop()) + " Coins)"
    if buy_cow_pen_btn:
        buy_cow_pen_btn.text = "Cow Pen (-" + str(inv.get_bp_price_cow_pen()) + " Coins)"
    if buy_bakery_btn:
        buy_bakery_btn.text = "Bakery (-" + str(inv.get_bp_price_bakery()) + " Coins)"
    if buy_mill_btn:
        buy_mill_btn.text = "Mill (-" + str(inv.get_bp_price_mill()) + " Coins)"
    if stock_info_label:
        stock_info_label.text = "Stock: " + str(inv.bp_wheat) + " W | " + str(inv.bp_tomato) + " T | " + str(inv.bp_potato) + " P | " + str(inv.bp_coop) + " C | " + str(inv.bp_cow_pen) + " CP | " + str(inv.bp_bakery) + " B | " + str(inv.bp_mill) + " M"
    
    if tomato_label:
        tomato_label.text = "Tomato: " + str(inv.tomato_stock)
    if potato_label:
        potato_label.text = "Potato: " + str(inv.potato_stock)
        
    var world = get_node_or_null("/root/World")
    if world and buy_chicken_btn and buy_cow_btn:
        if world.has_empty_pen("COOP"):
            buy_chicken_btn.text = "Buy Chicken (-20 Coins)"
            buy_chicken_btn.disabled = false
        else:
            buy_chicken_btn.text = "Buy Chicken (Need Coop!)"
            buy_chicken_btn.disabled = true
            
        if world.has_empty_pen("COW_PEN"):
            buy_cow_btn.text = "Buy Cow (-40 Coins)"
            buy_cow_btn.disabled = false
        else:
            buy_cow_btn.text = "Buy Cow (Need Cow Pen!)"
            buy_cow_btn.disabled = true

func _update_upgrade_panel_info():
    var f_manager = get_node("/root/FarmManager")
    var inv = get_node("/root/InventoryManager")
    var lvl = f_manager.get_tile_level(current_upgrade_cell)
    
    var type_str = "Plot"
    var effect_str = "Yield: " + str(lvl) + " -> " + str(lvl + 1)
    
    var real_state = f_manager.get_tile_state(current_upgrade_cell)
    if real_state == f_manager.TileState.BAKERY:
        type_str = "Bakery"
        effect_str = "Efficiency: " + str(int(pow(1.5, lvl-1)*100)) + "% -> " + str(int(pow(1.5, lvl)*100)) + "%"
    elif real_state == f_manager.TileState.MILL:
        type_str = "Mill"
        effect_str = "Efficiency: " + str(int(pow(1.5, lvl-1)*100)) + "% -> " + str(int(pow(1.5, lvl)*100)) + "%"
    
    if lvl < 5:
        var price = f_manager.get_tile_upgrade_price(current_upgrade_cell)
        upgrade_info_label.text = type_str + " Lv " + str(lvl) + "\n" + effect_str + "\nCost: " + str(price) + " Coins"
        upgrade_btn.disabled = inv.money < price
        upgrade_btn.visible = true
    else:
        upgrade_info_label.text = type_str + " Lv " + str(lvl) + "\n(MAX LEVEL)"
        upgrade_btn.visible = false
