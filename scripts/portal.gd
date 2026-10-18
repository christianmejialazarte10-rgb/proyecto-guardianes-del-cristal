extends Area2D

var activated: bool = false
## Evita disparar el final más de una vez.
var victory_shown: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	QuestManager.quest_completed.connect(activate_portal)


func activate_portal() -> void:
	activated = true

	if sprite.sprite_frames.has_animation("active"):
		sprite.play("active")

	print("Portal activado")


## El final del juego: el jugador atraviesa el portal ya activado.
func _on_body_entered(body: Node2D) -> void:
	if not activated or victory_shown:
		return

	if not body.is_in_group("player"):
		return

	victory_shown = true
	print("¡Nivel completado!")

	var current := get_tree().current_scene
	if current != null and current.has_method("show_victory"):
		current.show_victory()
