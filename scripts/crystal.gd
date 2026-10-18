extends Area2D

signal collected

var was_collected: bool = false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if was_collected:
		return

	if not body.is_in_group("player"):
		return

	# Paso de verificación obligatorio: consultar al QuestManager.
	if QuestManager.is_quest_active == true:
		# Misión activa: sumar 1 al contador, refrescar el HUD y
		# destruir el cristal inmediatamente.
		if QuestManager.collect_crystal():
			was_collected = true
			update_hud()
			collected.emit()
			queue_free()

	# Misión NO activa: no se hace nada. El jugador pasa por encima
	# sin recoger el cristal y el cristal permanece en la escena.


func update_hud() -> void:
	var tree := get_tree()

	if tree == null or tree.current_scene == null:
		return

	var hud := tree.current_scene.get_node_or_null("GameHUD")

	if hud != null and hud.has_method("update_quest_info"):
		hud.update_quest_info()
