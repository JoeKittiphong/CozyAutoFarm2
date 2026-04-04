extends CanvasLayer

var wheat_label: Label
var flour_label: Label
var egg_label: Label
var milk_label: Label
var mode_btn: Button
var mill_btn: Button

func _ready() -> void:
    var panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
    panel.custom_minimum_size = Vector2(0, 80)
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.15, 0.1, 0.1, 0.9)
    panel.add_theme_stylebox_override("panel", style)
    
    var hbox = HBoxContainer.new()
    hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    hbox.add_theme_constant_override("separation", 20)
    
    # Textures/Labels
    wheat_label = _create_resource_ui(hbox, "res://assets/sprites/wheat_item.png", "Wheat: 0")
    flour_label = _create_resource_ui(hbox, "res://assets/sprites/flour_bag.png", "Flour: 0")
    egg_label = _create_resource_ui(hbox, "res://assets/sprites/egg_item.png", "Eggs: 0")
    milk_label = _create_resource_ui(hbox, "res://assets/sprites/milk_bucket.png", "Milk: 0")
    
    # Mill Toggle
    mill_btn = Button.new()
    mill_btn.text = "Mill: ON"
    mill_btn.pressed.connect(_on_mill_pressed)
    hbox.add_child(mill_btn)

    var btn_worker = Button.new()
    btn_worker.text = "Hire Worker (-2 Flour)"
    btn_worker.pressed.connect(_on_hire_pressed)
    hbox.add_child(btn_worker)
    
    var btn_chicken = Button.new()
    btn_chicken.text = "Buy Chicken (-5F)"
    btn_chicken.pressed.connect(_on_buy_chicken_pressed)
    hbox.add_child(btn_chicken)
    
    var btn_cow = Button.new()
    btn_cow.text = "Buy Cow (-10F)"
    btn_cow.pressed.connect(_on_buy_cow_pressed)
    hbox.add_child(btn_cow)
    
    mode_btn = Button.new()
    mode_btn.text = "Mode: WHEAT"
    mode_btn.pressed.connect(_on_mode_pressed)
    hbox.add_child(mode_btn)
    
    panel.add_child(hbox)
    add_child(panel)
    
    var inv = get_node_or_null("/root/InventoryManager")
    if inv:
        inv.resources_updated.connect(_on_resources_updated)

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
        if inv.spend_flour(5):
            world._spawn_animal_at_shop("CHICKEN")

func _on_buy_cow_pressed() -> void:
    var world = get_node_or_null("/root/World")
    if world and world.has_empty_pen("COW_PEN"):
        var inv = get_node("/root/InventoryManager")
        if inv.spend_flour(10):
            world._spawn_animal_at_shop("COW")

func _on_mode_pressed() -> void:
    var world = get_node_or_null("/root/World")
    if world:
        if world.placement_mode == "WHEAT":
            world.placement_mode = "COOP"
        elif world.placement_mode == "COOP":
            world.placement_mode = "COW_PEN"
        else:
            world.placement_mode = "WHEAT"
        mode_btn.text = "Mode: " + world.placement_mode

func _on_mill_pressed() -> void:
    var inv = get_node("/root/InventoryManager")
    inv.mill_paused = not inv.mill_paused
    if inv.mill_paused:
        mill_btn.text = "Mill: PAUSED"
    else:
        mill_btn.text = "Mill: ON"

func _on_resources_updated() -> void:
    var inv = get_node("/root/InventoryManager")
    wheat_label.text = "Wheat: " + str(inv.wheat_stock)
    flour_label.text = "Flour: " + str(inv.flour_stock)
    egg_label.text = "Eggs: " + str(inv.egg_stock)
    milk_label.text = "Milk: " + str(inv.milk_stock)
