extends HBoxContainer
class_name ResourceItemComponent

@onready var _icon: TextureRect = $Icon
@onready var _value_label: Label = $ValueLabel

func configure(icon_path: String, text: String) -> void:
	_icon.texture = load(icon_path)
	_value_label.text = text

func set_text(text: String) -> void:
	_value_label.text = text

func get_label() -> Label:
	return _value_label
