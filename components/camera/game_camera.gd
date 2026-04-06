extends Camera2D
class_name GameCamera

@export var pan_speed: float = 800.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.2
@export var max_zoom: float = 2.0

var _is_dragging: bool = false
var _drag_start_mouse_pos: Vector2 = Vector2.ZERO
var _drag_start_camera_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_setup_input_map()

func _process(delta: float) -> void:
	_handle_keyboard_pan(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_is_dragging = true
				_drag_start_mouse_pos = event.position
				_drag_start_camera_pos = position
			else:
				_is_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var target_zoom = clamp(zoom.x + zoom_speed, min_zoom, max_zoom)
			zoom = Vector2(target_zoom, target_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var target_zoom = clamp(zoom.x - zoom_speed, min_zoom, max_zoom)
			zoom = Vector2(target_zoom, target_zoom)
	elif event is InputEventMouseMotion and _is_dragging:
		var diff = (event.position - _drag_start_mouse_pos) / zoom.x
		position = _drag_start_camera_pos - diff

func _handle_keyboard_pan(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("camera_up"):
		direction.y -= 1
	if Input.is_action_pressed("camera_down"):
		direction.y += 1
	if Input.is_action_pressed("camera_left"):
		direction.x -= 1
	if Input.is_action_pressed("camera_right"):
		direction.x += 1
	if direction.length_squared() > 0:
		position += direction.normalized() * pan_speed * delta / zoom.x

func frame_world_rect(world_rect: Rect2, padding: Vector2 = Vector2(256, 192), left_ui_width: float = 0.0) -> void:
	if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var padded_size: Vector2 = world_rect.size + padding * 2.0
	var available_size: Vector2 = Vector2(max(viewport_size.x - left_ui_width, 1.0), max(viewport_size.y, 1.0))
	var fit_zoom: float = min(available_size.x / padded_size.x, available_size.y / padded_size.y)
	fit_zoom = clamp(fit_zoom, min_zoom, 1.0)
	zoom = Vector2(fit_zoom, fit_zoom)

	var center: Vector2 = world_rect.get_center()
	if left_ui_width > 0.0:
		center.x += (left_ui_width * 0.5) / fit_zoom
	position = center

func _setup_input_map() -> void:
	var mappings = {
		"camera_up": KEY_W,
		"camera_down": KEY_S,
		"camera_left": KEY_A,
		"camera_right": KEY_D,
	}

	for action in mappings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

		var has_key = false
		for evt in InputMap.action_get_events(action):
			if evt is InputEventKey and evt.keycode == mappings[action]:
				has_key = true
				break

		if not has_key:
			var ev = InputEventKey.new()
			ev.keycode = mappings[action]
			InputMap.action_add_event(action, ev)
