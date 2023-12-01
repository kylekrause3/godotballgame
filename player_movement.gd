extends RigidBody3D

var forward : Vector3 = Vector3(1, 0, 0);

var move_input : Vector2

@export var base_speed : float = 25
@export var max_velocity : float = 50
@export var jump_velocity : float = 10.0
@export var sprint_speed : float = 35
@export var velocity_label : Label
@export var jumptime_label : Label

var local_rotation : float = 0

var velocity : Vector3 = Vector3(0, 0, 0)

var is_on_floor : bool = false
var rolling_resistance : float = 0.3

var applied_speed : float = base_speed

var do_teleport : bool = false
var teleport_location : Vector3 = Vector3.ZERO

var spawn : Vector3 = Vector3(0, 2, 0)

var jump_held : bool = false
var jump_held_time : float = 0
var jump_held_max_secs : float = 0.35
var display_jumptime : float = 0

func _ready():
	pass

func _physics_process(delta):	
	var xz_velocity : float = abs(linear_velocity.x) + abs(linear_velocity.z) /2
	var dir : Vector3 = Vector3()
	#movement input
	move_input = Input.get_vector("left","right","down","up")
	dir += move_input.x * Vector3.RIGHT
	dir += move_input.y * Vector3.FORWARD
	
	applied_speed = base_speed
	if Input.is_action_pressed("sprint"):
		applied_speed = sprint_speed
	
	dir = dir.rotated(Vector3(0, 1, 0), deg_to_rad(local_rotation))
	velocity = dir * applied_speed
	if is_on_floor:
		apply_central_force(velocity)
	else:
		apply_central_force(velocity / 3)
	
	if Input.is_action_just_pressed("jump") and is_on_floor:
		is_on_floor = false
		apply_central_impulse(Vector3.UP * jump_velocity)
		jump_held = true # toggle jump held (higher jump for longer hold)
	
	# longer jumps if jump key is pressed and held
	if jump_held and Input.is_action_pressed("jump"):
		jump_held_time += delta
		if jump_held_time < jump_held_max_secs:
			apply_central_impulse(Vector3.UP * jump_velocity * delta)
			display_jumptime = jump_held_time
		else:
			display_jumptime = jump_held_max_secs
	else:
		jump_held = false
		jump_held_time = 0
	
	
	var display_velocity : String = "Velocity:\t" + str(int(xz_velocity * 10) / 10.0)
	velocity_label.text = display_velocity
	jumptime_label.text = "Hold time:\t" + str(int(display_jumptime * 100) / 100.0)


func _integrate_forces(state):
	# govern speed of object
	if state.linear_velocity.x > max_velocity || state.linear_velocity.y > max_velocity:
		state.linear_velocity = state.linear_velocity.normalized() * max_velocity
	# i should actually look up how to do a proper friction system 
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


func change_orientation(y_rot : float) -> void:
	local_rotation += y_rot
	while local_rotation > 360:
		local_rotation -= 360
	while local_rotation < 0:
		local_rotation += 360
		

func set_grounded(condition : bool, _body : Node) -> void:
	is_on_floor = condition
# https://github.com/Chevifier/Rigid-Body-FPS-Controller-Tutorial/blob/main/RBPlayer.gd
