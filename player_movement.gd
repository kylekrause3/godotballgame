# todo:
#  - when not grounded, can change rotation in direction of wasd, can add sort of sm64 backflip this way as well
# 
#  - monitor if just_grounded , if just_grounded && ctrl_held, add ground-pound window:
#      (grace period where you can jump regardless of ground [if ground pounded physical object and it moved] and jump slightly higher)

extends RigidBody3D

var move_input : Vector2

@export var base_speed : float = 55
@export var max_velocity : float = 100
@export var jump_velocity : float = 15
@export var jump_held_max_secs : float = 0.4
@export var sprint_speed : float = 75
@export var velocity_label : Label
@export var jumptime_label : Label

@export var ground_line : Node3D
@export var camera : Camera3D

@onready var camera_fov : float = camera.fov

var camera_rotation : float = 0

var wish_velocity : Vector3 = Vector3(0, 0, 0)

var is_on_floor : bool = false
var rolling_resistance : float = 0.3

var applied_speed : float = base_speed

var do_teleport : bool = false
var teleport_location : Vector3 = Vector3.ZERO

var spawn : Vector3 = Vector3(0, 2, 0)

var jump_held : bool = false
var jump_held_time : float = 0

var display_jumptime : float = 0

var ground_bodies : int = 0

@onready var set_gravity_scale = self.gravity_scale

func _ready():
	pass

func _physics_process(delta):
	var xz_velocity : Vector3 = Vector3(linear_velocity.x, 0, linear_velocity.z)
	var dir : Vector3 = Vector3()
	#movement input
	move_input = Input.get_vector("left","right","down","up")
	dir += move_input.x * Vector3.RIGHT
	dir += move_input.y * Vector3.FORWARD
	dir = dir.rotated(Vector3(0, 1, 0), deg_to_rad(camera_rotation)) # rotate wish dir by camera location
	dir = dir.normalized()
	
	var brake_help : float = 1.0
	# dot product between normalized wish direction and velocity direction for braking
	var amount_forward = dir.dot(Vector3(linear_velocity.x, 0, linear_velocity.z).normalized())
	if amount_forward < 0: # if we are trying to slow the ball down
		brake_help = 1 + abs(amount_forward)
	applied_speed = base_speed
	camera.set_desired_fov(camera_fov)
	if Input.is_action_pressed("sprint"):
		applied_speed = sprint_speed
		camera.set_desired_fov(camera_fov + 10)
	
	# Translate input direction into force
	wish_velocity = dir * applied_speed
	if xz_velocity.length() < max_velocity: # else, just apply steering
		if is_on_floor:
			apply_central_force(wish_velocity * brake_help)
		else:
			apply_central_force((wish_velocity * brake_help) / 3)
	else: # find wish_velocity component perpendicular to xz_velocity, see https://www.youtube.com/watch?v=CIVRlgjZ6LI
		# magnitude of parallel component of wish_velocity on xz_velocity
		var parallel_magnitude : float = wish_velocity.dot(xz_velocity)/xz_velocity.length()
		
		# two parallel vectors are proportional by their magnitudes
		var parallel_component : Vector3 = parallel_magnitude * (xz_velocity / xz_velocity.length())
		
		# remove all wish_velocity parallel to forward, this is steering amount
		var wish_perpendicular : Vector3 = wish_velocity - parallel_component
		
		if is_on_floor: # brake_help should always be 1 here
			apply_central_force(wish_perpendicular * brake_help)
		else:
			apply_central_force((wish_perpendicular * brake_help) / 3)
	
	# jumping
	if Input.is_action_just_pressed("jump") && is_on_floor:
		is_on_floor = false
		apply_central_impulse(Vector3.UP * jump_velocity)
		jump_held = true # toggle jump held (higher jump for longer hold)
	
	if jump_held && Input.is_action_pressed("jump"):
		jump_held_time += delta
		if jump_held_time < jump_held_max_secs:
			apply_central_impulse(Vector3.UP * jump_velocity * delta)
			display_jumptime = jump_held_time
		else:
			display_jumptime = jump_held_max_secs
	else:
		jump_held = false
		jump_held_time = 0
	
	
	# slam
	self.gravity_scale = set_gravity_scale
	if Input.is_action_pressed("slam"):
		self.gravity_scale = 10
	
	
	# screen stuff
	var display_velocity : String = "Velocity:\t" + str(int(xz_velocity.length() * 10) / 10.0)
	velocity_label.text = display_velocity
	jumptime_label.text = "Hold time:\t" + str(int(display_jumptime * 100) / 100.0)
	
	ground_line.set_draw(!is_on_floor)


func _integrate_forces(state):
	# use physics material for more proper friction system
	# apply force of friction
	if state.linear_velocity.length() > 0 and is_on_floor:
		var friction : Vector3 = Vector3.ONE * rolling_resistance * 9.8 * self.mass
		apply_central_force(state.linear_velocity.normalized() * -1 * friction)
	if do_teleport:
		var new_transform : Transform3D = state.get_transform()
		new_transform.origin.x = teleport_location.x
		new_transform.origin.y = teleport_location.y
		new_transform.origin.z = teleport_location.z
		state.set_transform(new_transform)
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		do_teleport = false


func _input(event):
	if event.is_action_pressed("reset"):
		self.teleport(spawn)


func teleport(pos : Vector3) -> void:
	do_teleport = true
	teleport_location = pos


func set_spawn(pos : Vector3) -> void:
	self.spawn = pos


# ensure that the wasd direction matches where the camera is facing
func change_cam_orientation(y_rot_amt : float) -> void: 
	camera_rotation += y_rot_amt
	while camera_rotation > 360:
		camera_rotation -= 360
	while camera_rotation < 0:
		camera_rotation += 360
		

func add_ground_count() -> void:
	ground_bodies += 1
	is_on_floor = true


func remove_ground_count() -> void:
	ground_bodies -= 1
	is_on_floor = ground_bodies > 0
