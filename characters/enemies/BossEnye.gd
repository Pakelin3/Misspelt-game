extends CharacterBody2D

@export var base_speed: float = 120.0
@export var dash_speed: float = 550.0
@export var damage: int = 30
@export var max_hp: int = 1200 

var current_hp: int = max_hp
var player: Node2D = null
var is_active: bool = true
var knockback_velocity: Vector2 = Vector2.ZERO

# --- MÁQUINA DE ESTADOS ---
enum State { FOLLOW, DASH, COOLDOWN }
var current_state = State.FOLLOW
var state_timer: float = 2.0
var dash_direction: Vector2 = Vector2.ZERO

var tilde_scene = preload("res://entities/projectiles/TildeProjectile.tscn")

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if not is_active or not player: return

	state_timer -= delta

	match current_state:
		State.FOLLOW:
			var direction = global_position.direction_to(player.global_position)
			velocity = (direction * base_speed) + knockback_velocity
			
			if state_timer <= 0:
				start_dash()

		State.DASH:
			velocity = dash_direction * dash_speed
			if state_timer <= 0:
				shoot_tilde()
				current_state = State.COOLDOWN
				state_timer = 1.0 

		State.COOLDOWN:
			velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta) + knockback_velocity
			if state_timer <= 0:
				current_state = State.FOLLOW
				state_timer = randf_range(2.0, 4.0)

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1500 * delta)
	move_and_slide()

	if has_node("Hitbox"):
		for body in $Hitbox.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(damage)
			elif body.is_in_group("enemy") and body != self:
				if body.has_method("die_by_boss"):
					body.die_by_boss()

func start_dash():
	current_state = State.DASH
	state_timer = 0.3 
	dash_direction = global_position.direction_to(player.global_position)
	modulate = Color(2, 0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)

func shoot_tilde():
	var tilde = tilde_scene.instantiate()
	tilde.global_position = global_position
	tilde.direction = dash_direction 
	tilde.boss_ref = self
	get_tree().current_scene.add_child(tilde)

func apply_knockback(push_dir: Vector2, strength: float):
	if not is_active: return
	knockback_velocity = push_dir * (strength * 0.5)

func take_damage(amount: int):
	if not is_active: return
	current_hp -= amount

	modulate = Color(2.5, 2.5, 2.5)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

	if current_hp <= 0:
		die()

func die():
	is_active = false
	print("¡La Ñ ha sido domada!")	
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	
	GameManager.bosses_killed += 1
	var drop = preload("res://entities/items/XPGem.tscn").instantiate()
	drop.xp_value = 150
	drop.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", drop)
	
	EventBus.boss_enye_died.emit()
	queue_free()
