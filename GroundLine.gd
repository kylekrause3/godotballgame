extends RayCast3D

@export var target : Node3D

var LineDrawer = preload("res://DrawLine3D.gd").new()
var do_draw : bool = false

var line_color : Color = Color(0, 255, 100)


# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(LineDrawer)
	self.target_position = Vector3(0, -100, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position = target.position
	
	var collision_point = self.get_collision_point()
	if self.is_colliding() && do_draw:
		if target.position.y > collision_point.y:
			LineDrawer.DrawLine(target.position, collision_point, line_color)
		LineDrawer.DrawSquare(collision_point, 1.0, line_color)


func set_draw(condition : bool):
	do_draw = condition;
