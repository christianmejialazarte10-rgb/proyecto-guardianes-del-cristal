extends CanvasLayer

## Señales táctiles expuestas al resto del juego.
signal movement_changed(direction: Vector2)
signal joystick_released
signal attack_pressed
signal attack_released
signal interact_pressed
signal interact_released

## Radio máximo de desplazamiento del knob (px).
@export var joystick_radius: float = 65.0
## Zona muerta del joystick (fracción del radio).
@export var deadzone: float = 0.15
## Margen respecto al borde inferior/derecho de la pantalla (px).
@export var button_margin: float = 46.0

@onready var controls: Control = $Controls
@onready var joystick_base: Control = $Controls/JoystickBase
@onready var joystick_knob: Control = $Controls/JoystickBase/JoystickKnob
@onready var attack_button: TouchScreenButton = $Controls/AttackButton
@onready var interact_button: TouchScreenButton = $Controls/InteractButton

## Dirección analógica actual del joystick (-1..1 por eje).
var joystick_direction: Vector2 = Vector2.ZERO
## Índice del dedo que controla el joystick (-1 si ninguno).
var active_touch_index: int = -1


func _ready() -> void:
	attack_button.pressed.connect(_on_attack_button_pressed)
	attack_button.released.connect(_on_attack_button_released)
	interact_button.pressed.connect(_on_interact_button_pressed)
	interact_button.released.connect(_on_interact_button_released)

	layout_controls()
	reset_joystick()


## Coloca el joystick abajo-izquierda y los botones abajo-derecha
## en función del tamaño real de la pantalla.
func layout_controls() -> void:
	var view: Vector2 = controls.size
	if view == Vector2.ZERO:
		view = get_viewport().get_visible_rect().size

	var attack_size: Vector2 = button_size(attack_button)
	var interact_size: Vector2 = button_size(interact_button)

	attack_button.position = Vector2(
		view.x - attack_size.x - button_margin,
		view.y - attack_size.y - button_margin
	)
	interact_button.position = Vector2(
		view.x - attack_size.x - interact_size.x - button_margin * 2.0,
		view.y - attack_size.y - button_margin
	)

	joystick_knob.position = knob_home()


func button_size(button: TouchScreenButton) -> Vector2:
	if button.texture_normal != null:
		return button.texture_normal.get_size()

	return Vector2(118.0, 118.0)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if active_touch_index == -1 and is_inside_joystick(event.position):
				active_touch_index = event.index
				update_joystick(event.position)
		elif event.index == active_touch_index:
			active_touch_index = -1
			reset_joystick()
	elif event is InputEventScreenDrag:
		if event.index == active_touch_index:
			update_joystick(event.position)


func joystick_center() -> Vector2:
	return joystick_base.get_global_rect().get_center()


func knob_home() -> Vector2:
	return (joystick_base.size - joystick_knob.size) / 2.0


func is_inside_joystick(screen_position: Vector2) -> bool:
	return screen_position.distance_to(joystick_center()) <= joystick_radius * 1.6


## Desplazamiento analógico: mueve el knob y publica la dirección.
func update_joystick(screen_position: Vector2) -> void:
	var delta: Vector2 = screen_position - joystick_center()
	var clamped: Vector2 = delta.limit_length(joystick_radius)

	joystick_knob.position = knob_home() + clamped

	if delta.length() <= deadzone * joystick_radius:
		joystick_direction = Vector2.ZERO
	else:
		joystick_direction = clamped / joystick_radius

	apply_movement(joystick_direction)
	movement_changed.emit(joystick_direction)


## Suelta el joystick: knob al centro y acciones de movimiento liberadas.
func reset_joystick() -> void:
	active_touch_index = -1
	joystick_direction = Vector2.ZERO
	joystick_knob.position = knob_home()

	apply_movement(Vector2.ZERO)
	movement_changed.emit(Vector2.ZERO)
	joystick_released.emit()


## Traduce la dirección del joystick a las acciones de movimiento del InputMap.
func apply_movement(direction: Vector2) -> void:
	set_action_strength("move_right", maxf(direction.x, 0.0))
	set_action_strength("move_left", maxf(-direction.x, 0.0))
	set_action_strength("move_down", maxf(direction.y, 0.0))
	set_action_strength("move_up", maxf(-direction.y, 0.0))


func set_action_strength(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, clampf(strength, 0.0, 1.0))
	else:
		Input.action_release(action)


func _on_attack_button_pressed() -> void:
	Input.action_press("player_attack")
	attack_pressed.emit()


func _on_attack_button_released() -> void:
	Input.action_release("player_attack")
	attack_released.emit()


func _on_interact_button_pressed() -> void:
	Input.action_press("interact")
	interact_pressed.emit()


func _on_interact_button_released() -> void:
	Input.action_release("interact")
	interact_released.emit()
