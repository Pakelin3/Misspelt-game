extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10

var direction: Vector2 = Vector2.RIGHT
var is_active: bool = true
var max_pierce: int = 0
var current_pierce: int = 0
var hit_enemies: Array = []

func _ready():
	$VisibleOnScreenNotifier2D.screen_exited.connect(deactivate)
	body_entered.connect(_on_body_entered)
	
func _physics_process(delta):
	if not is_active: 
		return
	position += direction * speed * delta
	
func _on_body_entered(body):
	if not is_active: return
	if body.is_in_group("player"): return
	if body.is_in_group("obstacle"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		call_deferred("deactivate")
		return
	if body.is_in_group("enemy"):
		if body in hit_enemies:
			return
		
		if body.has_method("take_damage"):
			body.take_damage(damage)
			hit_enemies.append(body)
		
		current_pierce += 1
		if current_pierce > max_pierce:
			call_deferred("deactivate")

# --- FUNCIONES DEL OBJECT POOLING ---

func deactivate():
	is_active = false
	hide() 
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func activate(spawn_pos: Vector2, spawn_rot: float, new_dir: Vector2, dmg: int, player: Node2D = null, pierce: int = 0):
	global_position = spawn_pos
	rotation = spawn_rot
	direction = new_dir
	damage = dmg
	max_pierce = pierce
	current_pierce = 0
	hit_enemies.clear()
	
	is_active = true
	show() 
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
