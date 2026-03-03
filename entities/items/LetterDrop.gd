extends Area2D

var letter_char: String = "A"
var is_active: bool = true

func _ready():
	var tween = create_tween().set_loops()
	tween.tween_property($Label, "position:y", -10.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
	tween.tween_property($Label, "position:y", 10.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not is_active: return
	if body.is_in_group("player"):
		var success = body.collect_letter(letter_char) 
		call_deferred("deactivate")

func deactivate():
	is_active = false
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func activate(spawn_pos: Vector2, new_char: String):
	letter_char = new_char
	$Label.text = letter_char
	global_position = spawn_pos
	scale = Vector2(1, 1)
	
	is_active = true
	show()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
