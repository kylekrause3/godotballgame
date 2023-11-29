extends Node3D

@export var player : Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	# future: make general 'player' script, in player script call child tp
	player.get_node("RBPlayer").teleport(self.position)
	player.get_node("RBPlayer").set_spawn(self.position)
