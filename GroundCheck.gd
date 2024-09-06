extends Area3D

@export var target : Node = get_parent()
@onready var y_offset : float = self.position.y


func _process(_delta):
	self.position.x = target.position.x
	self.position.y = target.position.y 
	self.position.z = target.position.z


func _on_body_entered(body):
	target.add_ground()


func _on_body_exited(body):
	target.remove_ground()
