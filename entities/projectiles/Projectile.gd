extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10

var direction: Vector2 = Vector2.RIGHT
var is_active: bool = true

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
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
		call_deferred("deactivate")

# --- FUNCIONES DEL OBJECT POOLING ---

func deactivate():
	is_active = false
	hide() 
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func activate(spawn_pos: Vector2, spawn_rot: float, new_dir: Vector2, dmg: int):
	global_position = spawn_pos
	rotation = spawn_rot
	direction = new_dir
	damage = dmg
	
	is_active = true
	show() 
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
