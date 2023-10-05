extends Camera3D

@onready var target = get_parent().get_node("RBPlayer")
@export var orbit_radius : float = 7.0
@export var view_sensitivity : float = 1.0
@export var orient_target : bool = true
@export var zoom_fov : bool = false

var mouse_input : Vector2 = Vector2.ZERO
var view_sensitivity_scalar : float = 0.25

var do_mouse_movement : bool = true

func _ready():
	if target == null:
		target.position = self.position
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	view_sensitivity *= view_sensitivity_scalar

func _process(_delta):
	self.position = target.position
	
	self.position += orbit_radius * get_backward(self.rotation)
	# TODO: Add collider to camera so you can free rotate if theres no floor
	if(self.position.y - target.position.y < 0):
		self.position.y = target.position.y

func _input(event):	
	if event is InputEventMouseMotion and do_mouse_movement:
		self.rotation_degrees.x -= event.relative.y * view_sensitivity
		self.rotation_degrees.x = clamp(self.rotation_degrees.x, -89, 89)
		self.rotation_degrees.y -= event.relative.x * view_sensitivity
		
		if orient_target:
			target.change_orientation(-event.relative.x * view_sensitivity)
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				do_mouse_movement = true
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if zoom_fov:
				self.fov -= 0.5
			else:
				orbit_radius -= 0.1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if zoom_fov:
				self.fov += 0.5
			else:
				orbit_radius += 0.1
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				do_mouse_movement = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func get_backward(rot : Vector3) -> Vector3:
	var ret : Vector3 = Vector3(0, 0, 1);
	ret = ret.rotated(Vector3(1, 0, 0), rot.x)
	ret = ret.rotated(Vector3(0, 1, 0), rot.y)
	return ret.normalized()

