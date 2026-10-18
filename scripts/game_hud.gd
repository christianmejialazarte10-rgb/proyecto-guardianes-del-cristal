extends CanvasLayer

## Spritesheet de vida: 6 marcos de 28 px (5 corazones rojos + 1 gris vacío).
const HEART_SHEET: String = "res://assets/ui/44_corazones_vida.png"
const HEART_SIZE: Vector2 = Vector2(28.0, 47.0)
## Coordenada X del corazón lleno (rojo) y del corazón vacío (gris).
const HEART_FULL_X: float = 6.0
const HEART_EMPTY_X: float = 140.0

@onready var hearts_container: HBoxContainer = \
	$HUDContainer/HeartsPanel/HeartsContainer
@onready var crystal_label: Label = $HUDContainer/CrystalsPanel/CrystalLabel
@onready var quest_label: Label = $HUDContainer/QuestPanel/QuestLabel

var heart_full: AtlasTexture
var heart_empty: AtlasTexture


func _ready() -> void:
	build_heart_textures()

	QuestManager.quest_updated.connect(update_quest_info)
	update_quest_info()


## Recorta el spritesheet en dos AtlasTexture: corazón lleno y corazón vacío.
func build_heart_textures() -> void:
	var sheet: Texture2D = load(HEART_SHEET)

	heart_full = AtlasTexture.new()
	heart_full.atlas = sheet
	heart_full.region = Rect2(HEART_FULL_X, 0.0, HEART_SIZE.x, HEART_SIZE.y)

	heart_empty = AtlasTexture.new()
	heart_empty.atlas = sheet
	heart_empty.region = Rect2(HEART_EMPTY_X, 0.0, HEART_SIZE.x, HEART_SIZE.y)

	for heart in hearts_container.get_children():
		heart.texture = heart_full


func heart_count() -> int:
	return hearts_container.get_child_count()


## Pinta los corazones según la vida: lleno mientras quede vida en ese corazón.
func update_health(current: int, maximum: int) -> void:
	var total: int = heart_count()

	if total == 0:
		return

	var safe_max: int = maxi(maximum, 1)
	var per_heart: float = float(safe_max) / float(total)

	for i in total:
		var heart: TextureRect = hearts_container.get_child(i)
		var remaining: float = float(current) - float(i) * per_heart
		heart.texture = heart_full if remaining > 0.0 else heart_empty


func update_quest_info() -> void:
	crystal_label.text = "Cristales: %d/%d" % [
		QuestManager.collected_crystals,
		QuestManager.required_crystals
	]
	match QuestManager.quest_state:
		QuestManager.QuestState.NOT_STARTED:
			quest_label.text = "Mision: Habla con Han Solo"
		QuestManager.QuestState.ACTIVE:
			quest_label.text = "Mision: Recoger cristales"
		QuestManager.QuestState.READY_TO_DELIVER:
			quest_label.text = "Mision: Entrega los cristales a Han Solo"
		QuestManager.QuestState.COMPLETED:
			quest_label.text = "¡Completado!"
