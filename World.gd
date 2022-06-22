extends Spatial

onready var path = get_node("Track1/Path")
onready var path_follow = get_node("Track1/Path/PathFollow")


var car_list = []
onready var carsNode = get_node("Cars")

func get_path_direction(position):
	var offset = path.curve.get_closest_offset(position)
	path_follow.offset = offset
	return path_follow.transform.basis.z


func _process(delta):
	if Input.is_action_just_pressed("reload"):
		get_tree().reload_current_scene()


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
#	Global.num_of_checkpoints = get_node("Track1/CheckPointAreas/").get_child_count()
