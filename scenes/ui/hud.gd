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
var buy_chicken_btn: Button
var buy_cow_btn: Button
var stock_info_label: Label
var tomato_label: Label
var potato_label: Label

func _ready() -> void:
    # 1. Top Bar
    var top_panel = PanelContainer.new()
    top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top_panel.custom_minimum_size = Vector2(0, 80)
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
    
    var inv = get_node_or_null("/root/InventoryManager")
    if inv:
        inv.resources_updated.connect(_on_resources_updated)
        _on_resources_updated()

func _create_resource_ui(parent: Node, icon_path: String, start_val: String) -> Label:
    var bx = HBoxContainer.new()
    var tex = TextureRect.new()
    tex.texture = load(icon_path)
    tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH
    tex.custom_minimum_size = Vector2(40, 40)
    tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var lbl = Label.new()
    lbl.text = start_val
    lbl.add_theme_font_size_override("font_size", 20)
    bx.add_child(tex)
    bx.add_child(lbl)
    parent.add_child(bx)
    return lbl

func _setup_shop_ui():
    shop_panel = PanelContainer.new()
    shop_panel.set_anchors_preset(Control.PRESET_CENTER)
    shop_panel.custom_minimum_size = Vector2(400, 300)
    shop_panel.visible = false
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.15, 0.1, 0.95)
    style.border_width_bottom = 4
    style.border_width_top = 4
    style.border_width_left = 4
    style.border_width_right = 4
    style.border_color = Color(0.8, 0.6, 0.2)
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    shop_panel.add_theme_stylebox_override("panel", style)
    
    var vbox = VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 15)
    
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
    worker_panel.set_anchors_preset(Control.PRESET_CENTER)
    worker_panel.custom_minimum_size = Vector2(300, 450)
    worker_panel.visible = false
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.15, 0.2, 0.1, 0.95)
    style.border_width_bottom = 4
    style.border_width_top = 4
    style.border_width_left = 4
    style.border_width_right = 4
    style.border_color = Color(0.4, 0.8, 0.2)
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    worker_panel.add_theme_stylebox_override("panel", style)
    
    var vbox = VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 15)
    
    var title = Label.new()
    title.text = "--- WORKER HOUSE ---"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)
    
    hire_worker_btn = Button.new()
    hire_worker_btn.pressed.connect(_on_hire_pressed)
    vbox.add_child(hire_worker_btn)
    
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

func toggle_shop():
    shop_panel.visible = not shop_panel.visible
    if shop_panel.visible:
        worker_panel.visible = false

func toggle_worker_house():
    worker_panel.visible = not worker_panel.visible
    if worker_panel.visible:
        shop_panel.visible = false

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
        hire_worker_btn.text = "Hire Worker (-" + str(inv.get_worker_price()) + " Coins)"
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
