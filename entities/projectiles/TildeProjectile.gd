extends Area2D

var speed: float = 500.0
var damage: int = 15
var direction: Vector2 = Vector2.RIGHT
var max_distance: float = 400.0

var start_pos: Vector2
var returning: bool = false
var boss_ref: Node2D = null

func _ready():
	start_pos = global_position
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	rotation += 15.0 * delta 
	
	if not returning:
		position += direction * speed * delta
		if global_position.distance_to(start_pos) > max_distance:
			returning = true
	else:
		if is_instance_valid(boss_ref):
			var dir_to_boss = global_position.direction_to(boss_ref.global_position)
			position += dir_to_boss * speed * delta
			if global_position.distance_to(boss_ref.global_position) < 30.0:
				queue_free()
		else:
			queue_free() 

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			# Opcional: desaparecer al golpear o seguir cortando (si quieres que sea hardcore, quita el queue_free)
			queue_free()
