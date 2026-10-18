extends Node2D

@onready var crystal_label: Label = \
	$GameHUD/HUDContainer/CrystalsPanel/CrystalLabel

@onready var player = $player

@onready var game_hud = $GameHUD

@onready var win_screen: CanvasLayer = \
	$WinScreen


func _ready() -> void:
	var crystals := $crystals.get_children()

	for crystal in crystals:
		if not crystal.collected.is_connected(
			_on_crystal_collected
		):
			crystal.collected.connect(
				_on_crystal_collected
			)

	player.health_changed.connect(game_hud.update_health)
	game_hud.update_health(player.health, player.max_health)


func _on_crystal_collected() -> void:
	update_crystal_label()
	print("Cristales: %d/%d" % [
		QuestManager.collected_crystals,
		QuestManager.required_crystals
	])

## Pantalla verde de victoria: congela al jugador y a los enemigos.
## Se dispara cuando el jugador atraviesa el portal con la misión entregada.
func show_victory() -> void:
	if win_screen.visible:
		return

	var dialogue = get_node_or_null("DialogueUI")
	if dialogue != null and dialogue.is_open:
		dialogue.close_dialogue()

	win_screen.visible = true

	if player.has_method("freeze"):
		player.freeze()
	else:
		player.velocity = Vector2.ZERO

	for guard in $guards.get_children():
		if guard is CharacterBody2D:
			guard.velocity = Vector2.ZERO
		guard.process_mode = Node.PROCESS_MODE_DISABLED

	print("¡VICTORIA! Has recolectado los 3 cristales")


func update_crystal_label() -> void:
	crystal_label.text = "Cristales: %d/%d" % [
		QuestManager.collected_crystals,
		QuestManager.required_crystals
	]
