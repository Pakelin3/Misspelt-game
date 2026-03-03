extends Node2D

var enemy_scene = preload("res://scenes/Enemy.tscn")
var letter_drop_scene = preload("res://scenes/LetterDrop.tscn")
var gem_scene = preload("res://scenes/XPGem.tscn")

@onready var spawn_location = $SpawnPath/SpawnLocation
@onready var spawn_timer = $SpawnTimer

var difficulty_level: int = 1
var time_since_start: float = 0.0

# --- NUESTRAS PISCINAS ---
var enemy_pool: Array = []
var letter_pool: Array = []
var gem_pool: Array = []

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = 1.5

func _process(delta):
	time_since_start += delta
	var new_level = 1 + int(time_since_start / 15.0) 
	
	if new_level > difficulty_level:
		difficulty_level = new_level
		increase_difficulty()

func increase_difficulty():
	print("¡PELIGRO! Nivel de Horda: ", difficulty_level)
	var new_wait_time = max(0.1, 1.5 * pow(0.95, difficulty_level))
	spawn_timer.wait_time = new_wait_time

# --- SISTEMA DE POOLING ---
func get_enemy() -> CharacterBody2D:
	for enemy in enemy_pool:
		if not enemy.is_active: return enemy
		
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_died.connect(_on_enemy_died) 
	get_tree().current_scene.add_child(new_enemy)
	enemy_pool.append(new_enemy)
	return new_enemy

func get_letter() -> Area2D:
	for letter in letter_pool:
		if not letter.is_active: return letter
		
	var new_letter = letter_drop_scene.instantiate()
	get_tree().current_scene.add_child(new_letter)
	letter_pool.append(new_letter)
	return new_letter

func get_gem() -> Area2D:
	for gem in gem_pool:
		if not gem.is_active: return gem
		
	var new_gem = gem_scene.instantiate()
	get_tree().current_scene.add_child(new_gem)
	gem_pool.append(new_gem)
	return new_gem

# --- SPAWNERS ---
func _on_spawn_timer_timeout():
	var horde_count = 1 + int(difficulty_level / 5)
	
	for i in range(horde_count):
		spawn_location.progress_ratio = randf()
		
		var char_to_spawn = "A"
		if GameManager and GameManager.target_word != "":
			var word = GameManager.target_word.to_upper()
			var valid_chars = word.replace(" ", "").replace("_", "")
			if valid_chars.length() > 0:
				var random_index = randi() % valid_chars.length()
				char_to_spawn = valid_chars[random_index]

		var enemy = get_enemy()
		var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		enemy.activate(spawn_location.global_position + offset, difficulty_level, char_to_spawn)

func _on_enemy_died(spawn_pos: Vector2, char_letter: String):
	call_deferred("spawn_loot_deferred", spawn_pos, char_letter)
	
func spawn_loot_deferred(spawn_pos: Vector2, char_letter: String):
	var gem = get_gem()
	gem.activate(spawn_pos)
	if char_letter != "":
		var letter = get_letter()
		letter.activate(spawn_pos, char_letter)
