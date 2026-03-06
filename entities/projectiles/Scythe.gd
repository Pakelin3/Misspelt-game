extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10
@export var max_distance: float = 400.0 
@export var return_speed_multiplier: float = 1.5

var direction: Vector2 = Vector2.RIGHT
var is_active: bool = true
var is_returning: bool = false
var start_position: Vector2
var max_pierce: int = 0
var current_pierce: int = 0
var hit_enemies: Array = []

var player_ref: Node2D = null

func _ready():
	$VisibleOnScreenNotifier2D.screen_exited.connect(deactivate)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if not is_active: 
		return
		
	$Sprite2D.rotation += 15.0 * delta
		
	if not is_returning:
		position += direction * speed * delta
		
		if global_position.distance_to(start_position) >= max_distance:
			start_return()
	else:
		if is_instance_valid(player_ref):
			var dir_to_player = (player_ref.global_position - global_position).normalized()
			position += dir_to_player * (speed * return_speed_multiplier) * delta
			
			if global_position.distance_to(player_ref.global_position) < 30.0:
				deactivate()
		else:
			deactivate()

func _on_body_entered(body):
	if not is_active: return
	
	if body.is_in_group("player"): 
		if is_returning:
			deactivate()
		return
		
	if body.is_in_group("obstacle"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if not is_returning:
			start_return()
		return
		
	if body.is_in_group("enemy"):
		if body in hit_enemies:
			return 
			
		if body.has_method("take_damage"):
			body.take_damage(damage)
			hit_enemies.append(body)
			
		if not is_returning:
			current_pierce += 1
			if max_pierce != -1 and current_pierce > max_pierce:
				start_return()

func start_return():
	if is_returning: return
	is_returning = true
	hit_enemies.clear() 

func deactivate():
	is_active = false
	hide() 
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func activate(spawn_pos: Vector2, spawn_rot: float, new_dir: Vector2, dmg: int, player: Node2D, pierce: int = 0):
	global_position = spawn_pos
	direction = new_dir
	damage = dmg
	start_position = spawn_pos
	
	player_ref = player
	max_pierce = pierce
	current_pierce = 0
	is_returning = false
	hit_enemies.clear()
	
	is_active = true
	show() 
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
