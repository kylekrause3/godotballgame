extends Camera3D

@export var target : Node
@export var orbit_radius : float = 7.0
@export var view_sensitivity : float = 1.0
@export var orient_target : bool = true
@export var raycast : RayCast3D
@export var zoom_fov : bool = false
@export var zoom_amount : float = 0.5

var mouse_input : Vector2 = Vector2.ZERO
var view_sensitivity_scalar : float = 0.25

var do_mouse_movement : bool = true

var touching_ground : bool = false
var ground_body : Node = null

var addpos : Vector3 = Vector3.ZERO
var last_addpos : Vector3 = Vector3.ZERO

var collision_mask = 0b00000000_00000000_00000000_00000001

func _ready():
	if target == null:
		target.position = self.position
	self.rotation = target.rotation
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	view_sensitivity *= view_sensitivity_scalar
	raycast.add_exception(target)


func _process(_delta):
	self.position = target.position
	var backward = get_backward(self.rotation)
	
	raycast.position = target.position
	raycast.target_position = Vector3(0, 0, 1)
	raycast.scale = Vector3(1, 1, orbit_radius)
	'ret = ret.rotated(Vector3(1, 0, 0), rot.x)
	ret = ret.rotated(Vector3(0, 1, 0), rot.y)'
	raycast.rotation = Vector3(self.rotation.x, self.rotation.y, 0)
	if(raycast.is_colliding()):
		var distance = target.position.distance_to(raycast.get_collision_point())
		self.position += distance * backward
		
		# self.position += raycast.get_collision_point()		
	else:
		self.position += orbit_radius * backward
	
	
	
	# if(raycast.is_colliding()) stoppign here, realized i cant do it stemming from camera bah
	'if(touching_ground):
		if(self.position.y < ground_body.position.y):
			self.position.y = ground_body.position.y'
	'if(self.position.y < target.position.y):
		self.position.y = target.position.y'
	# TODO: Add collider to camera so you can free rotate if theres no floor

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
				self.fov -= zoom_amount
			else:
				if orbit_radius - zoom_amount > 0:
					orbit_radius -= zoom_amount
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if zoom_fov:
				self.fov += zoom_amount
			else:
				orbit_radius += zoom_amount
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

