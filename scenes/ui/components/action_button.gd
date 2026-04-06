extends Button
class_name ActionButtonComponent

signal action_pressed(action_id: String)

var action_id: String = ""

func _ready() -> void:
	if not pressed.is_connected(_emit_action_pressed):
		pressed.connect(_emit_action_pressed)

func configure_action(id: String, text_value: String = "") -> void:
	action_id = id
	text = text_value

func set_button_text(text_value: String) -> void:
	text = text_value

func _emit_action_pressed() -> void:
	action_pressed.emit(action_id)
