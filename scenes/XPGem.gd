extends Area2D

@export var xp_value: int = 10
var is_active: bool = true

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not is_active: return
	if body.is_in_group("player"):
		body.gain_xp(xp_value)
		call_deferred("deactivate")

func deactivate():
	is_active = false
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func activate(spawn_pos: Vector2):
	global_position = spawn_pos
	is_active = true
	show()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
