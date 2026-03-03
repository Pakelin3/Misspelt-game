extends Node2D

@onready var bg_grass = $ParallaxBackground/ParallaxLayer/Sprite2D
@onready var clouds_layer = $ParallaxBackground/CloudsLayer
@onready var parallax_layer = $ParallaxBackground/ParallaxLayer
@onready var player = $Player

@onready var template_flower_1 = $ParallaxBackground/ParallaxLayer/Flower1
@onready var template_flower_2 = $ParallaxBackground/ParallaxLayer/Flower2

func _ready():
	print("Game.gd: _ready start")
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

func apply_difficulty_environment():
	var difficulty = int(GameManager.game_data.get("difficulty", 2))
	
	print("Game.gd: Cargando Mundo para dificultad: ", difficulty)
	
	if difficulty == 1:
		setup_easy_world()
	elif difficulty == 2:
		setup_normal_world()
	elif difficulty >= 3:
		setup_hard_world()

func setup_easy_world():
	bg_grass.texture = preload("res://images/assets/grass.png")
	clouds_layer.show()
	generate_flowers(40)
	
	if player.has_node("AmbientParticles"):
		player.get_node("AmbientParticles").emitting = true

func setup_normal_world():
	bg_grass.texture = preload("res://images/assets/rocks.png")
	
	clouds_layer.hide()
	if player.has_node("AmbientParticles"):
		player.get_node("AmbientParticles").emitting = false
		
	# (Aquí luego llamaremos al spawner de rocas destructibles)

func setup_hard_world():
	# bg_grass.texture = preload("res://images/assets/library_floor.png")
	clouds_layer.hide()
	if player.has_node("AmbientParticles"):
		player.get_node("AmbientParticles").emitting = false

func _process(delta):
	if clouds_layer.visible:
		clouds_layer.motion_offset += Vector2(15.0, 10.0) * delta
