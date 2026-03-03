extends StaticBody2D

var hp: int = 30 
var player_ref: Node2D = null

func _ready():
	player_ref = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if is_instance_valid(player_ref):
		if global_position.distance_to(player_ref.global_position) > 2000:
			queue_free()

func take_damage(amount: int):
	hp -= amount
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0:
		queue_free() # En el futuro soltara oro/items
