extends Area3D

@onready var player : Node = get_parent().get_node("RBPlayer")
@onready var y_offset : float = self.position.y


func _process(delta):
	self.position.x = player.position.x
	self.position.y = player.position.y + y_offset
	self.position.z = player.position.z


func _on_body_entered(body):
	player.set_grounded(true)


func _on_body_exited(body):
	player.set_grounded(false)
