extends Control
class_name UI

export var debug = true
export(Array, Texture) var faces

onready var healthbar = $Healthbar
onready var combo = $Combo


# Called when the node enters the scene tree for the first time.
func _ready():
	$HealthButton.visible = debug


func set_next_combo_face(face_number):
	combo.texture = faces[face_number-1]


func set_current_faces(main, top, bottom, left, right):
	$MainFace.texture = main
	$MainFace/Top.texture = top
	$MainFace/Bottom.texture = bottom
	$MainFace/Left.texture = left
	$MainFace/Right.texture = right


func set_health(health):
	healthbar.set_health(health)
