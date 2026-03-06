extends CharacterBody2D

signal enemy_died(spawn_pos, char_letter) 

@export var base_speed: float = 100.0
@export var base_damage: int = 10
@export var base_hp: int = 20 

var speed: float = 100.0
var damage: int = 10
var hp: int = 20 
var player: Node2D = null
var my_char: String = "" 
var is_active: bool = true
var knockback_velocity: Vector2 = Vector2.ZERO

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(_delta):
	if not is_active: return
	
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = (direction * speed) + knockback_velocity
		move_and_slide()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1500 * _delta)
		
		for body in $Hitbox.get_overlapping_bodies():
			if body.is_in_group("player"):
				if body.has_method("take_damage"):
					body.take_damage(damage)
				var push_direction = body.global_position.direction_to(global_position)
				velocity = push_direction * (speed * 5) 
				move_and_slide()
	else:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1500 * _delta)
		move_and_slide()

func apply_knockback(push_dir: Vector2, strength: float):
	if not is_active: return
	knockback_velocity = push_dir * strength

func take_damage(amount: int):
	if not is_active: return 
	
	hp -= amount
	modulate = Color(1,0,0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1), 0.1)
	
	if hp <= 0:
		die()

func die():
	if not is_active: return 
	is_active = false 
	print("Enemigo derrotado")
	GameManager.letters_killed += 1
	emit_signal("enemy_died", global_position, my_char)
	
	_play_death_sound()
	call_deferred("deactivate")

func die_by_boss():
	if not is_active: return
	is_active = false
	print("Enemigo devorado por el jefe")
	
	_play_death_sound()
	call_deferred("deactivate")

func _play_death_sound():
	var sfx = AudioStreamPlayer2D.new()
	sfx.stream = preload("res://music/letter_death.mp3")
	sfx.volume_db = -18.0 
	sfx.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", sfx)
	sfx.call_deferred("play")
	sfx.finished.connect(sfx.queue_free)

func deactivate():
	hide()
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func activate(spawn_pos: Vector2, level: int, char_letter: String):
	my_char = char_letter
	$Label.text = my_char
	
	var hp_multiplier = pow(1.15, level - 1)
	hp = int(base_hp * hp_multiplier)
	speed = base_speed + (level * 2.0) 
	damage = base_damage + int(level * 0.5)
	
	var scale_bonus = 1.0 + min(level * 0.02, 0.5) 
	scale = Vector2(scale_bonus, scale_bonus)
	
	global_position = spawn_pos
	modulate = Color(1,1,1)
	
	is_active = true
	show()
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", false)
		
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
