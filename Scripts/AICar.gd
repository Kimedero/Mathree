extends VehicleBody

onready var springArm = get_node("camera_pivot/SpringArm")
var mouse_sensitivity = 0.4

onready var ContextRays = get_node("ContextRays")

var steer_angle = deg2rad(45)
export var steer_speed : float = 40#20#5#3

export var horsepower = 450#900#1000#600#750#700#500
export var acceleration_speed = 80#40#20#80

export var brake_power = 40
export var brake_speed = 40

var braking_factor : float = 0.0

var dir_factor = 1
var turn_factor = 1

export var timer_wait_time = 1.5

# ai
var num_rays = 16#32
var look_ahead = 12
var brake_distance :int = 5
var interest = []
var danger = []
var chosen_dir = Vector3.ZERO
var forward_ray

var issue_count = 0

onready var upsideDownRayCast = get_node("Raycasts/UpsideDownRayCast")
onready var rightForwardStoppageRayCast = get_node("Raycasts/rightForwardStoppageRayCast")
onready var leftForwardStoppageRayCast = get_node("Raycasts/leftForwardStoppageRayCast")

onready var frontRightSideRayCast = get_node("Raycasts/frontRightSideRayCast")
onready var frontLeftSideRayCast = get_node("Raycasts/frontLeftSideRayCast")
onready var rearRightSideRayCast = get_node("Raycasts/rearRightSideRayCast")
onready var rearLeftSideRayCast = get_node("Raycasts/rearLeftSideRayCast")

onready var stoppageTimer = get_node("Timers/stoppageTimer")
var stoppageTimerStarted = false
onready var flippedTimer = get_node("Timers/flippedTimer")
var flippedTimerStarted = false
onready var tippedTimer = get_node("Timers/tippedTimer")
var tippedTimerStarted = false

var carStopped = false
var frontBlocked = false
var carFlipped = false
var carTipped = false

var carAboutToHitWall = false

onready var statsLabel = get_node("Text/StatsLabel")
onready var frontDistanceRaycast = get_node("Raycasts/FrontDistanceRayCast")

var carVel : float = 1.0
onready var carVelTimer = get_node("Timers/carVelTimer")
var carVelTimerStarted = false
var carVelTimerWaitTime = 0.1
var distanceRayColliding = false
var rayBlockLowerLimit : float = 0.5#2.5#20.0#15.0 #25.0
var rayBlockUpperLimit : float = 80.0 # the higher the more risk-averse

var reset_count = 0

var brake_input : float = 0.0

export(Curve) var vel_curve
export(Curve) var brake_curve

var ray_collision_distance = 1.0

#onready var tailLights = get_node("black/tail light glass")

#var emissiveMaterial

var originalVel = 0.0

onready var brakeTimer = get_node("Timers/brakeTimer")
var brakeTimerStarted = false
var brakeTimerWaitTime = 0.2

var car_speed = 0.0

var lap = 0
var curr_checkpoint = "StartLine"

func _ready():
	interest.resize(num_rays)
	danger.resize(num_rays)
	add_rays()
	
	rayBlockUpperLimit = frontDistanceRaycast.cast_to.length() #.y
	
#	emissiveMaterial = tailLights.mesh.surface_get_material(0)
#	emissiveMaterial.set_feature(1, false)


func add_rays():
	var angle = 2 * PI / num_rays
	for i in num_rays:
		var r = RayCast.new()
		ContextRays.add_child(r)
		r.cast_to = Vector3.FORWARD * look_ahead
		r.rotation.y = -angle * i
		r.enabled = true
#		I added this line to make the raycast cast to the car mask bit and the track mask bit
		r.set_collision_mask_bit(0, true)
		r.set_collision_mask_bit(1, true)
	forward_ray = ContextRays.get_child(0)


func _input(event):
	var mouse_movement = event as InputEventMouseMotion
	if mouse_movement:
		springArm.rotation_degrees.y -= mouse_movement.relative.x * mouse_sensitivity
		springArm.rotation_degrees.x -= mouse_movement.relative.y * mouse_sensitivity
		springArm.rotation_degrees.x = clamp(springArm.rotation_degrees.x , -30, 15)


func _physics_process(delta):
	# to have a unified speed query point
	car_speed = linear_velocity.length()
	
	if frontDistanceRaycast.is_colliding():
		var origin = frontDistanceRaycast.global_transform.origin
		var collision_point = frontDistanceRaycast.get_collision_point()
		ray_collision_distance = origin.distance_to(collision_point)
	else:
		ray_collision_distance = rayBlockUpperLimit
	
	# CAR CORRECTION CHECKS
	# to figure out if car is stopped
	if linear_velocity.length_squared() < 9.0: #4.0#1.0
		carStopped = true
	else:
		carStopped = false
	
	# to figure out if car is blocked at the front
	if rightForwardStoppageRayCast.is_colliding() or leftForwardStoppageRayCast.is_colliding():
		frontBlocked = true
	else:
		frontBlocked = false
	
	# to establish if car is fliiiiiiiiiiped over
	if upsideDownRayCast.is_colliding():
		carFlipped = true
	else:
		carFlipped = false
	
	# to test if the raycast is colliding with walls
	if frontDistanceRaycast.is_colliding():
		distanceRayColliding = true
	else:
		distanceRayColliding = false

	# to establish if car is tipped to the side along a wall
	if (not frontLeftSideRayCast.is_colliding() and not rearLeftSideRayCast.is_colliding()) or (not frontRightSideRayCast.is_colliding() and not rearRightSideRayCast.is_colliding()) and not carFlipped:
		carTipped = true
	else:
		carTipped = false
	
	# TIMER TRIGGERS
	# car stoppage
	if carStopped and frontBlocked:
		if not stoppageTimerStarted:
			stoppageTimerStarted = true
			stoppageTimer.start(timer_wait_time)
	
	# car flip
	if carStopped and carFlipped:
		if not flippedTimerStarted:
			flippedTimerStarted = true
			flippedTimer.start(timer_wait_time)
	
	# car tip
	if carTipped:
		if not tippedTimerStarted:
			tippedTimerStarted = true
			tippedTimer.start(timer_wait_time)
	
	# to test if we should reduce the velocity
	if distanceRayColliding and not carStopped:
		if not carVelTimerStarted:
			carVelTimerStarted = true
			carVelTimer.start(carVelTimerWaitTime)
	else:
		carVel = 1.0
	
	# to test if we should brake
	if distanceRayColliding and not carStopped:
		if not brakeTimerStarted:
			brakeTimerStarted = true
			brakeTimer.start(brakeTimerWaitTime)
		else:
			brake_input = 0.0

#	var drive_input = Input.get_axis("accelerate", "reverse")
#	var drive_input = 1 * dir_factor
	var drive_input = carVel * dir_factor
#	engine_force = lerp(engine_force, drive_input * horsepower, acceleration_speed * delta)
	engine_force = drive_input * horsepower
	
#	var steering_input = Input.get_axis("turn_right", "turn_left")
	var steering_input = angle_dir(transform.basis.z, chosen_dir, transform.basis.y) * turn_factor
	steering = lerp_angle(steering, steering_input * steer_angle, steer_speed * delta)
	
#	var brake_input = 0
#	brake_input = Input.get_action_strength("brake") / 4
#	brake = lerp(brake, brake_input * brake_power, brake_speed * delta)
	brake = brake_input * brake_power


func _process(delta):
	set_interest()
	set_danger()
	choose_direction()

#	statsLabel.text = str(name) +" - " + str(ray_collision_distance)  + "m - " + str(carVel) + " - " + str(int(linear_velocity.length() * 3.6)) + " KM/H" + " - " + str(brake_input)
#	statsLabel.text = str(name) +": " + str(int(car_speed * 3.6)) + " KM/H - " + str(int(ray_collision_distance)) + "m - " +  str(carVel) + " - " + str(brake_input) 
	if name == "AICar":
		statsLabel.text = str(name) + ": " + str(int(car_speed * 3.6)) + " KM/H - LAP: " + str(lap) + " - " + curr_checkpoint #+ " - " + str(Global.num_of_checkpoints)



func set_interest():
	var path_direction = -transform.basis.z
	if owner and owner.has_method("get_path_direction"):
		path_direction = owner.get_path_direction(global_transform.origin)
	for i in num_rays:
		var d = -ContextRays.get_child(i).global_transform.basis.z
		d = d.dot(path_direction)
		interest[i] = max(0, d)


func set_danger():
	for i in num_rays:
		var ray = ContextRays.get_child(i)
		danger[i] = 1 if ray.is_colliding() else 0


func choose_direction():
	for i in num_rays:
		if danger[i] > 0:
			interest[i] = 0
	chosen_dir = Vector3.ZERO
	for i in num_rays:
		chosen_dir += -ContextRays.get_child(i).global_transform.basis.z * interest[i]
	chosen_dir = chosen_dir.normalized()


func angle_dir(fwd, target, up):
	# Returns how far "target" vector is to the left (negative)
	# or right (positive) of "fwd" vector.
	var p = fwd.cross(target)
	var dir = p.dot(up)
	return dir


func _on_stoppageTimer_timeout():
	if frontBlocked and carStopped:
		dir_factor = -1 # reverses the car
		turn_factor = -1 #turns the wheels the other way to get out of spot when reversing
		yield(get_tree().create_timer(timer_wait_time), "timeout") # creates a small timer to allow car to reverse
		dir_factor = 1
		turn_factor = 1
	stoppageTimerStarted = false


func _on_flippedTimer_timeout():
	if carFlipped and carStopped:
		# flips the car horizontally, taking into account its weight
		apply_torque_impulse(transform.basis.z * weight / 2)
	flippedTimerStarted = false


func _on_tippedTimer_timeout():
	# The car might be moving sideways but is tilted
	if carTipped and linear_velocity.length_squared() < 9.0:
		turn_factor = -1
		yield(get_tree().create_timer(timer_wait_time), "timeout") # adds a on-the-fly timer to reset the turn factor
		turn_factor = 1
	tippedTimerStarted = false


# slowing down when the car's front ray collides
func _on_carVelTimer_timeout():
	# uses a curve
	if ray_collision_distance > rayBlockLowerLimit:# and ray_collision_distance < rayBlockUpperLimit:
		carVel = ray_collision_distance / (vel_curve.interpolate(ray_collision_distance) * rayBlockUpperLimit)
#		emissiveMaterial.set_albedo(Color(1, 0, 0))
#		emissiveMaterial.set_feature(1, true)
	else:
		carVel = 1.0
#		emissiveMaterial.set_albedo(Color(1, 1, 1))
#		emissiveMaterial.set_feature(1, false)
	carVelTimerStarted = false


# to be used to help the car break on time
func _on_brakeTimer_timeout():
	if ray_collision_distance > rayBlockLowerLimit and car_speed > 15.0:
		brake_input = brake_curve.interpolate(ray_collision_distance / rayBlockUpperLimit)
#		if name == "AICar":
#			print(str(brake_input))
		yield(get_tree().create_timer(brakeTimerWaitTime), "timeout")
		brake_input = 0.0
	else:
		brake_input = 0.0
	brakeTimerStarted = false


func _on_Trigger_area_entered(area):
	if area.is_in_group("checkpoint"):
		curr_checkpoint = area.name
	if area.name == "CheckPoint1":
		lap += 1
