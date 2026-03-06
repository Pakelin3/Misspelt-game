extends StaticBody2D

var player_ref: Node2D = null

func _ready():
	player_ref = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if is_instance_valid(player_ref):
		if global_position.distance_to(player_ref.global_position) > 2000:
			queue_free()

func take_damage(_amount: int):
	pass
