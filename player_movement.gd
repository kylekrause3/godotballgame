extends RigidBody3D

var forward : Vector3 = Vector3(1, 0, 0);

var move_input : Vector2

@export var acceleration : float = 5
var accel_multiplier : float = 1.0
@export var base_speed : float = 25
@export var max_velocity : float = 50
@export var jump_velocity : float = 10.0
@export var sprint_speed : float = 35

var local_rotation : float = 0

var velocity : Vector3 = Vector3(0, 0, 0)

var is_on_floor : bool = false
var friction_amount : float = 0.1

var applied_speed : float = base_speed


func _ready():
	pass


func _physics_process(delta):
	var dir = Vector3()
	#movement input
	move_input = Input.get_vector("left","right","down","up")
	dir += move_input.x * Vector3.RIGHT
	dir += move_input.y * Vector3.FORWARD
	
	applied_speed = base_speed
	if Input.is_action_pressed("sprint"):
		applied_speed = sprint_speed
	
	dir = dir.rotated(Vector3(0, 1, 0), deg_to_rad(local_rotation))
	velocity = lerp(velocity,dir*applied_speed,acceleration*accel_multiplier*delta)
	apply_central_force(velocity)
	
	if Input.is_action_just_pressed("jump") and is_on_floor:
		accel_multiplier = 0.1
		is_on_floor = false
		apply_central_impulse(Vector3.UP * jump_velocity)


func _integrate_forces(state):
	# govern speed of object
	if state.linear_velocity.length() > max_velocity:
		state.linear_velocity = state.linear_velocity.normalized() * max_velocity
	# i should actually look up how to do a proper friction system 
	# apply force of friction
	if state.linear_velocity.length() > 0:
		state.linear_velocity -= state.linear_velocity.normalized() * friction_amount
#	if is_on_floor:
#		if state.linear_velocity.length() > 0.2:
#			var friction : Vector3 = Vector3(friction_amount, friction_amount, friction_amount)
#			apply_central_force(state.linear_velocity.normalized() * -1 * friction)
#		else:
#			state.linear_velocity *= 0


func _input(event):
	if event.is_action_pressed("reset"):
		self.teleport(Vector3(0, 2, 0))


func teleport(pos : Vector3) -> void:
	apply_central_impulse(-self.linear_velocity)
	self.set_position(pos)
	self.linear_velocity = Vector3.ZERO


func change_orientation(y_rot : float) -> void:
	local_rotation += y_rot
	while local_rotation > 360:
		local_rotation -= 360
	while local_rotation < 0:
		local_rotation += 360
		

func set_grounded(condition : bool) -> void:
	is_on_floor = condition
# https://github.com/Chevifier/Rigid-Body-FPS-Controller-Tutorial/blob/main/RBPlayer.gd
