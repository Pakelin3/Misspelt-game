extends Node2D

@onready var bg_grass = $ParallaxBackground/ParallaxLayer/Sprite2D
@onready var clouds_layer = $ParallaxBackground/CloudsLayer
@onready var parallax_layer = $ParallaxBackground/ParallaxLayer
@onready var player = $Player

@onready var template_flower_1 = $ParallaxBackground/ParallaxLayer/Flower1
@onready var template_flower_2 = $ParallaxBackground/ParallaxLayer/Flower2

var destructible_rock_scene = preload("res://entities/misc/DestructibleRock.tscn")
var big_rock_scene = preload("res://entities/misc/BigRock.tscn")
var pile_book_scene = preload("res://entities/misc/PileBook.tscn")
var prop_timer: Timer

var magic_material: ShaderMaterial

func _ready():
	magic_material = ShaderMaterial.new()
	magic_material.shader = preload("res://core/level/RandomOpacity.gdshader")
	
	prop_timer = Timer.new()
	prop_timer.wait_time = 3.0
	prop_timer.autostart = false
	prop_timer.timeout.connect(_on_prop_spawn)
	add_child(prop_timer)
	
	template_flower_1.hide()
	template_flower_2.hide()
	
	await get_tree().process_frame
	await get_tree().process_frame
	apply_difficulty_environment()

func generate_flowers(amount: int):
	var area_size = 2000
	
	for i in range(amount):
		var chosen_template = template_flower_1 if randf() > 0.5 else template_flower_2
		var new_flower = chosen_template.duplicate()
		new_flower.show()
		new_flower.position = Vector2(randf_range(0, area_size), randf_range(0, area_size))
		parallax_layer.add_child(new_flower)

func generate_scattered_props(textures: Array, amount: int, min_dist: float):
	var area_x = parallax_layer.motion_mirroring.x
	var area_y = parallax_layer.motion_mirroring.y
	if area_x == 0: area_x = 2000
	if area_y == 0: area_y = 2000
	
	var current_positions = []
	
	for i in range(amount):
		var attempts = 0
		var pos = Vector2.ZERO
		var valid_pos = false
		
		while attempts < 50 and not valid_pos:
			pos = Vector2(randf_range(0, area_x), randf_range(0, area_y))
			valid_pos = true
			for p in current_positions:
				if pos.distance_to(p) < min_dist:
					valid_pos = false
					break
			attempts += 1
			
		if valid_pos:
			current_positions.append(pos)
			var sprite = Sprite2D.new()
			sprite.texture = textures[randi() % textures.size()]
			sprite.position = pos
			sprite.scale = Vector2(1.5, 1.5)
			parallax_layer.add_child(sprite)

func apply_difficulty_environment():
	var difficulty = int(GameManager.game_data.get("difficulty", 2))	
	
	if difficulty == 1:
		setup_easy_world()
	elif difficulty == 2:
		setup_normal_world()
	elif difficulty >= 3:
		setup_hard_world()

func update_bg_tiling(new_texture: Texture, new_scale: Vector2, new_color: Color):
	bg_grass.texture = new_texture
	bg_grass.scale = new_scale
	bg_grass.modulate = new_color
	
	var base_size = 2016 
	bg_grass.region_rect = Rect2(0, 0, base_size, base_size)
	
	parallax_layer.motion_mirroring = Vector2(base_size * new_scale.x, base_size * new_scale.y)

func setup_easy_world():
	update_bg_tiling(preload("res://images/assets/grass.png"), Vector2(2.0, 2.0), Color.WHITE)
	bg_grass.material = null
	clouds_layer.show()
	generate_flowers(40)
	
	if player.has_node("AmbientParticles"):
		player.get_node("AmbientParticles").emitting = true

func setup_normal_world():
	update_bg_tiling(preload("res://images/assets/rocks.png"), Vector2(2, 2), Color(0.5, 0.5, 0.5))
	bg_grass.material = null
	
	clouds_layer.hide()
	if player.has_node("AmbientParticles"):
		player.get_node("AmbientParticles").emitting = false
		
	prop_timer.start(2.5)

func setup_hard_world():
	update_bg_tiling(preload("res://images/assets/magic_tile.png"), Vector2(2, 2), Color.WHITE)
	bg_grass.material = magic_material
	clouds_layer.hide()
	if player.has_node("AmbientParticles"):
		player.get_node("AmbientParticles").emitting = false
		
	var props = [
		preload("res://images/assets/scroll_1.png"),
		preload("res://images/assets/scroll_2.png")
	]
	generate_scattered_props(props, 40, 150.0)
	
	prop_timer.start(2.5)

func _process(delta):
	if clouds_layer.visible:
		clouds_layer.motion_offset += Vector2(15.0, 10.0) * delta

# --- GENERADOR INFINITO DE PROPS ---
func _on_prop_spawn():
	var difficulty = int(GameManager.game_data.get("difficulty", 2))
	if difficulty == 1: 
		return # En modo fácil no hay obstáculos
		
	if not is_instance_valid(player):
		return
		
	var player_pos = player.global_position
	var random_angle = randf() * TAU
	var spawn_distance = randf_range(700.0, 900.0)
	var spawn_pos = player_pos + Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	
	var prop_instance
	var r = randf()
	
	if difficulty >= 3:
		# Mundo difícil: Libros 40%, Rocas 40%, Rocas Grandes 20%
		prop_instance = pile_book_scene.instantiate()

	else:
		# Mundo normal: Solo rocas
		if r < 0.8:
			prop_instance = destructible_rock_scene.instantiate()
		else:
			prop_instance = big_rock_scene.instantiate()
		
	prop_instance.global_position = spawn_pos
	call_deferred("add_child", prop_instance)
