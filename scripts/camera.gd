extends Camera2D

const CAMERA_SPEED = 500.0
const ZOOM_SENSITIVITY = 0.03
const ZOOM_MIN = 0.5
const ZOOM_MAX = 3.0

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta):
	var dir = Input.get_vector("left", "right", "up", "down")
	position += dir * CAMERA_SPEED * delta
	_clamp_position()

func _unhandled_input(event):
	if event is InputEventMagnifyGesture:
		zoom = clamp(zoom * event.factor, Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))
		_clamp_position()
	elif event is InputEventPanGesture:
		var amount = event.delta.y * ZOOM_SENSITIVITY
		zoom = clamp(zoom - Vector2(amount, amount), Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))
		_clamp_position()
	elif event.is_action_pressed("zoom_in"):
		zoom = clamp(zoom - Vector2(0.1, 0.1), Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))
		_clamp_position()
	elif event.is_action_pressed("zoom_out"):
		zoom = clamp(zoom + Vector2(0.1, 0.1), Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))
		_clamp_position()

func _clamp_position():
	var half = get_viewport_rect().size / 2.0 / zoom
	position = position.clamp(
		Vector2(limit_left + half.x, limit_top + half.y),
		Vector2(limit_right - half.x, limit_bottom - half.y)
	)
