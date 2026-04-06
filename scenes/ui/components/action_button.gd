extends Button
class_name ActionButtonComponent

func configure(text_value: String, target: Object, method_name: String, binds: Array = []) -> void:
	text = text_value
	pressed.connect(Callable(target, method_name).bindv(binds))

func set_button_text(text_value: String) -> void:
	text = text_value
