# todo: camera acceleration with controller

extends Camera3D

@export var target : Node
@export var orbit_radius : float = 7.0
@export var view_sensitivity : float = 1.0
@export var controller_sensitivity : float = 50
@export var orient_target : bool = true
@export var raycast : RayCast3D
@export var zoom_fov_instead_of_distance : bool = false
@export var zoom_amount : float = 0.5
@export var fov_change_rate : float = 100
@export var camera_acceleration : float = 10

var mouse_input : Vector2 = Vector2.ZERO
var view_sensitivity_scalar : float = 0.25
var controller_sensitivity_scalar : float = 3.5

var do_mouse_movement : bool = true

var touching_ground : bool = false
var ground_body : Node = null

var addpos : Vector3 = Vector3.ZERO
var last_addpos : Vector3 = Vector3.ZERO
var lastpos : Vector3 = Vector3.ZERO
var joystick : Vector2 = Vector2.ZERO

var collision_mask = 0b00000000_00000000_00000000_00000001

@onready var desired_fov = self.fov

func _ready():
	if target == null:
		target.global_position = self.global_position
	lastpos = target.global_position
	self.rotation = target.rotation
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	view_sensitivity *= view_sensitivity_scalar
	controller_sensitivity *= controller_sensitivity_scalar
	


func _process(delta):
	joystick = Input.get_vector("cam_left","cam_right","cam_down","cam_up")
	if joystick != Vector2.ZERO:
		do_rotation(joystick.y * delta * controller_sensitivity, joystick.x * delta * controller_sensitivity)
		if orient_target:
			target.change_cam_orientation(-joystick.x * delta * controller_sensitivity)
	
	#self.global_position = lastpos.lerp(target.global_position, camera_acceleration * delta)
	self.global_position = target.global_position
	lastpos = self.global_position
	var backward = get_backward(self.rotation)
	
	raycast.global_position = self.global_position
	raycast.target_position = Vector3(0, 0, 1)
	raycast.scale = Vector3(1, 1, orbit_radius)
	raycast.rotation = Vector3(self.rotation.x, self.rotation.y, 0)
	if(raycast.is_colliding()):
		var distance = self.global_position.distance_to(raycast.get_collision_point())
		self.position += distance * backward
	else:
		self.position += orbit_radius * backward
	
	if self.fov - desired_fov > 0:
		self.fov -= delta * fov_change_rate
	elif self.fov - desired_fov < 0:
		self.fov += delta * fov_change_rate


func _input(event):	
	if event is InputEventMouseMotion and do_mouse_movement:
		do_rotation(-event.relative.y * view_sensitivity, event.relative.x * view_sensitivity)
		
		if orient_target: # ensure that the player knows where the camera is facing so that input direction and result movement match
			target.change_cam_orientation(-event.relative.x * view_sensitivity)
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				do_mouse_movement = true
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if zoom_fov_instead_of_distance:
				desired_fov -= zoom_amount
			else:
				if orbit_radius - zoom_amount > 0:
					orbit_radius -= zoom_amount
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if zoom_fov_instead_of_distance:
				desired_fov += zoom_amount
			else:
				orbit_radius += zoom_amount
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				do_mouse_movement = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func do_rotation(xrot : float, yrot : float):
	self.rotation_degrees.x += xrot
	self.rotation_degrees.x = clamp(self.rotation_degrees.x, -89, 89)
	self.rotation_degrees.y -= yrot


func get_backward(rot : Vector3) -> Vector3:
	var ret : Vector3 = Vector3(0, 0, 1);
	ret = ret.rotated(Vector3(1, 0, 0), rot.x)
	ret = ret.rotated(Vector3(0, 1, 0), rot.y)
	return ret.normalized()


func set_desired_fov(fov : float) -> void:
	desired_fov = fov
