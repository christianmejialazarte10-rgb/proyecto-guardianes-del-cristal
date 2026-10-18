extends Node2D

@onready var interactive_area: Area2D = $InteractiveArea
var player_nearby: bool = false
# true mientras el DialogBox muestra solo el saludo automático.
var greeting_open: bool = false
# Evita repetir el briefing de la misión en cada acercamiento.
var briefing_shown: bool = false

func _ready() -> void:
	interactive_area.body_entered.connect(
		_on_body_entered
	)

	interactive_area.body_exited.connect(
		_on_body_exited
	)

func _process(delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		interact()

## Devuelve el cuadro de diálogo y, de paso, se suscribe a su cierre.
func get_dialogue_ui():
	var current := get_tree().current_scene
	if current == null:
		return null

	var ui = current.get_node_or_null("DialogueUI")
	if ui == null:
		return null

	if ui.has_signal("dialogue_closed") \
			and not ui.dialogue_closed.is_connected(_on_dialogue_closed):
		ui.dialogue_closed.connect(_on_dialogue_closed)

	return ui

## Activa la misión en el QuestManager (inicia o finaliza la interacción
## con Han Solo) y actualiza la barra superior del HUD.
func activate_mission() -> bool:
	if QuestManager.quest_state == QuestManager.QuestState.COMPLETED:
		return false

	var ya_activa: bool = QuestManager.is_quest_active

	QuestManager.activate_quest()

	var current := get_tree().current_scene
	if current != null:
		var hud = current.get_node_or_null("GameHUD")
		if hud != null and hud.has_method("update_quest_info"):
			hud.update_quest_info()

	if not ya_activa:
		print("Mision: Recoger cristales")

	return true

func interact() -> void:
	var dialogue_ui = get_dialogue_ui()
	if dialogue_ui == null:
		return

	if dialogue_ui.is_open:
		# Si sólo se muestra el saludo automático de bienvenida,
		# se cierra para poder iniciar la conversación de la misión.
		if greeting_open:
			dialogue_ui.close_dialogue()
			greeting_open = false
		else:
			return
	else:
		greeting_open = false

	# Terminar de hablar con Han Solo también deja la misión activa.
	activate_mission()

	# --- Misión ya entregada ---
	if QuestManager.quest_state == QuestManager.QuestState.COMPLETED:
		var mensajes_final: Array[String] = [
			"¡Excelente trabajo!",
			"El portal está listo para ser utilizado.",
			"Buen viaje!"
		]
		dialogue_ui.show_dialogue(
			"Han Solo",
			mensajes_final
		)
		return

	# --- 1) Validación de cristales recolectados al hablar con el NPC ---
	if QuestManager.is_quest_active == true:
		if QuestManager.collected_crystals >= QuestManager.required_crystals:
			# Tiene los 3 cristales: entrega. El portal se activa y el
			# jugador debe atravesarlo para ganar (el final ocurre allí).
			var mensajes_ok: Array[String] = [
				"¡Excelente trabajo, trajiste todos los cristales!",
				"El portal está listo para ser utilizado.",
				"Corre hacia el portal y escapa de la ciudad!"
			]
			dialogue_ui.show_dialogue(
				"Han Solo",
				mensajes_ok
			)
			QuestManager.complete_quest()
		else:
			# Todavía le faltan cristales: recordatorio.
			var mensajes_faltan: Array[String] = [
				"Aún te faltan cristales por recolectar, búscalos en el mapa.",
				"Llevas %d de %d" % [
					QuestManager.collected_crystals,
					QuestManager.required_crystals
				]
			]
			dialogue_ui.show_dialogue(
				"Han Solo",
				mensajes_faltan
			)
		return

	# --- Respaldo: sin misión activa, se vuelve a ofrecer la ayuda ---
	var mensajes: Array[String] = [
		"Guardian, necesito tu ayuda!",
		"Los enemigos han dispersado los 3 cristales mágicos alrededor de la ciudad",
		"Recupéralos rápido y tráemelos antes de que se pierdan"
	]
	dialogue_ui.show_dialogue(
		"Han Solo",
		mensajes
	)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_nearby = true
	print("Han Solo: Welcome Sir")

	# Mostrar el cuadro de diálogo al entrar en la zona del NPC.
	var dialogue_ui = get_dialogue_ui()

	if dialogue_ui != null and not dialogue_ui.is_open:
		var bienvenida: Array[String] = [
			"Han Solo: Welcome Sir"
		]

		if not briefing_shown:
			briefing_shown = true
			bienvenida.append_array([
				"Guardian, necesito tu ayuda!",
				"Los enemigos han dispersado los 3 cristales mágicos alrededor de la ciudad",
				"Recupéralos rápido y tráemelos antes de que se pierdan"
			])

		dialogue_ui.show_dialogue(
			"Han Solo",
			bienvenida
		)
		greeting_open = true

	# El jugador inicia la interacción con Han Solo: activar la misión.
	activate_mission()

## El jugador cierra el cuadro: finaliza la interacción -> misión activa.
func _on_dialogue_closed() -> void:
	activate_mission()

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_nearby = false
