
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

@export var speed: float = 220.0
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_cooldown: float = 0.5

var health: int
var is_dead: bool = false
var is_attacking: bool = false
var attack_timer: float = 0.0
## true durante la pantalla de victoria: bloquea movimiento, ataque y daño.
var is_frozen: bool = false

@onready var attack_area: Area2D = $AttackArea
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")

	health = max_health
	health_changed.emit(health, max_health)

	animatedSprite.animation_finished.connect(
		_on_animation_finished
	)

	animatedSprite.play("idle")


func _physics_process(delta: float) -> void:
	if is_dead or is_frozen:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)

	if Input.is_action_just_pressed("player_attack"):
		attack()

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	# Giro horizontal del sprite según la dirección del movimiento.
	# "move_left" incluye la flecha izquierda (ui_left) y
	# "move_right" la flecha derecha (ui_right).
	if direction.x < 0.0:
		animatedSprite.flip_h = true
	elif direction.x > 0.0:
		animatedSprite.flip_h = false

	velocity = direction * speed
	move_and_slide()

	if not is_attacking:
		animatedSprite.play("idle")

func attack() -> void:
	if is_dead or is_frozen:
		return

	if is_attacking:
		return

	if attack_timer > 0.0:
		return

	is_attacking = true
	attack_timer = attack_cooldown

	animatedSprite.play("attack")

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			if body.has_method("take_damage"):
				body.take_damage(attack_damage)

func _on_animation_finished() -> void:
	match animatedSprite.animation:
		"attack":
			is_attacking = false

			if not is_dead and not is_frozen:
				animatedSprite.play("idle")
		"death":
			died.emit()

## Congela al jugador en la pantalla de victoria.
func freeze() -> void:
	is_frozen = true
	is_attacking = false
	velocity = Vector2.ZERO

func take_damage(amount: int) -> void:
	if is_dead or is_frozen:
		return

	health = maxi(health - amount, 0)

	health_changed.emit(health, max_health)

	if health == 0:
		is_dead = true
		is_attacking = false
		velocity = Vector2.ZERO
		animatedSprite.play("death")
