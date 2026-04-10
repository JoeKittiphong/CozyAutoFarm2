extends Button
class_name ActionButtonComponent

signal action_pressed(action_id: String)

enum DisplayMode {
	TEXT,
	CARD,
}

var action_id: String = ""
var _display_mode: DisplayMode = DisplayMode.TEXT
var _pending_title_text: String = ""
var _pending_price_text: String = ""
var _pending_badge_text: String = ""
var _pending_icon_texture: Texture2D = null

@onready var _content: VBoxContainer = $Content
@onready var _badge_label: Label = $BadgeLabel
@onready var _icon_rect: TextureRect = $Content/IconRect
@onready var _title_label: Label = $Content/TitleLabel
@onready var _price_label: Label = $Content/PriceLabel

func _ready() -> void:
	if not pressed.is_connected(_emit_action_pressed):
		pressed.connect(_emit_action_pressed)
	_apply_pending_content()
	_apply_display_mode()

func configure_action(id: String, text_value: String = "") -> void:
	action_id = id
	set_button_text(text_value)

func set_button_text(text_value: String) -> void:
	_pending_title_text = text_value
	tooltip_text = text_value
	if _title_label != null:
		_title_label.text = text_value

func set_display_mode(mode: String) -> void:
	match mode:
		"compact_cards":
			_display_mode = DisplayMode.CARD
		_:
			_display_mode = DisplayMode.TEXT
	_apply_display_mode()

func set_card_content(icon_texture: Texture2D, title_text: String, price_text: String) -> void:
	_pending_title_text = title_text
	_pending_price_text = price_text
	_pending_icon_texture = icon_texture
	tooltip_text = title_text
	_display_mode = DisplayMode.CARD
	_apply_pending_content()
	_apply_display_mode()

func set_badge_text(badge_text: String) -> void:
	_pending_badge_text = badge_text
	if _badge_label != null:
		_badge_label.text = badge_text
		_badge_label.visible = badge_text != ""

func _emit_action_pressed() -> void:
	action_pressed.emit(action_id)

func _apply_display_mode() -> void:
	if _content == null:
		return
	text = ""
	match _display_mode:
		DisplayMode.CARD:
			custom_minimum_size = Vector2(88, 88)
			size_flags_horizontal = 0
			alignment = HORIZONTAL_ALIGNMENT_CENTER
			_icon_rect.visible = true
			_price_label.visible = true
			_title_label.visible = false
			_badge_label.visible = _pending_badge_text != ""
			flat = false
		_:
			custom_minimum_size = Vector2(0, 40)
			size_flags_horizontal = Control.SIZE_EXPAND_FILL
			alignment = HORIZONTAL_ALIGNMENT_CENTER
			_icon_rect.visible = false
			_price_label.visible = false
			_title_label.visible = true
			_badge_label.visible = false
			flat = false

func _apply_pending_content() -> void:
	if _title_label == null or _price_label == null or _icon_rect == null or _badge_label == null:
		return
	_title_label.text = _pending_title_text
	_price_label.text = _pending_price_text
	_icon_rect.texture = _pending_icon_texture
	_badge_label.text = _pending_badge_text
	_badge_label.visible = _pending_badge_text != ""
