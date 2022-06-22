extends "res://Scripts/AICar.gd"

func _ready():
	weight = 3200
	acceleration_speed = 10
	horsepower = 800

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

