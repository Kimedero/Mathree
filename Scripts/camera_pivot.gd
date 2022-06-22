extends Spatial

var direction = Vector3.FORWARD
export (float, 1, 10, 0.1) var smooth_speed = 2.5

func _physics_process(delta):
	var current_velocity = get_parent().get_linear_velocity()
	current_velocity.y = 0
#	print(current_velocity.length_squared())
	if current_velocity.length_squared() > 1:
#		direction = lerp(direction, -current_velocity.normalized(), 2.5 * delta)
		direction = lerp(direction, current_velocity.normalized(), smooth_speed * delta)
		# set the rotation of the camera pivot to the direction we are moving towards
		# problem is we have a velocity vector and a rotation (basis)
	global_transform.basis = get_rotation_from_direction(direction)

func get_rotation_from_direction(look_direction : Vector3) -> Basis:
	# to reverse the camera you can negate the look_direction
	look_direction = look_direction.normalized()
	var x_axis = look_direction.cross(Vector3.UP)
	return Basis(x_axis, Vector3.UP, -look_direction)
