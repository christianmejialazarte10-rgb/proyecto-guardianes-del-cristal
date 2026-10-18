extends Node

signal quest_updated
signal quest_completed

enum QuestState {
	NOT_STARTED,
	ACTIVE,
	READY_TO_DELIVER,
	COMPLETED
}

var quest_state: QuestState = QuestState.NOT_STARTED
var required_crystals: int = 3
var collected_crystals: int = 0

# Estado global de la misión (usado por npc.gd y crystal.gd).
var is_quest_active: bool = false

# Alias de compatibilidad: apunta siempre a is_quest_active.
var is_mission_active: bool:
	get:
		return is_quest_active
	set(value):
		is_quest_active = value

func start_quest() -> void:
	if quest_state != QuestState.NOT_STARTED:
		return
	collected_crystals = 0
	quest_state = QuestState.ACTIVE
	is_quest_active = true
	quest_updated.emit()
	
## La llama npc.gd cuando el jugador inicia o finaliza la interacción
## con Han Solo. Mantiene sincronizados quest_state e is_quest_active y
## emite quest_updated para que el HUD pase a "Mision: Recoger cristales".
func activate_quest() -> void:
	if quest_state == QuestState.COMPLETED:
		is_quest_active = false
		return

	if quest_state == QuestState.NOT_STARTED:
		collected_crystals = 0
		quest_state = QuestState.ACTIVE

	is_quest_active = true
	quest_updated.emit()

func collect_crystal() -> bool:
	if not is_quest_active:
		return false
	collected_crystals += 1
	if collected_crystals >= required_crystals:
		quest_state = QuestState.READY_TO_DELIVER
	quest_updated.emit()
	return true

## La llama npc.gd al entregar los 3 cristales. Se valida por contador,
## no solo por estado, para que "collected_crystals == 3" sea decisivo.
func complete_quest() -> void:
	if quest_state == QuestState.COMPLETED:
		return

	if collected_crystals < required_crystals:
		return

	quest_state = QuestState.COMPLETED
	is_quest_active = false
	quest_updated.emit()
	quest_completed.emit()
