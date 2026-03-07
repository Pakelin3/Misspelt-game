extends Node2D

var projectile_scene = preload("res://entities/projectiles/Projectile.tscn") 
@onready var shooting_point = $ShootingPoint

var projectile_pool: Array = []

func set_projectile(scene_path: String):
	projectile_scene = load(scene_path)
	for proj in projectile_pool:
		if is_instance_valid(proj):
			proj.queue_free()
	projectile_pool.clear()

func _physics_process(_delta):
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest_enemy = null
	var min_dist = INF
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_enemy = enemy
	
	if nearest_enemy:
		look_at(nearest_enemy.global_position)

func get_projectile() -> Area2D:
	for proj in projectile_pool:
		if not proj.is_active:
			return proj
	
	var new_projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(new_projectile)
	projectile_pool.append(new_projectile)
	return new_projectile

func shoot():
	var player = get_parent()
	var base_damage = player.attack_damage if "attack_damage" in player else 10
	var extra_shots = player.additional_projectiles if "additional_projectiles" in player else 0
	var total_shots = 1 + extra_shots
	var spread_angle = deg_to_rad(15.0)
	var start_rotation = rotation - (spread_angle * (total_shots - 1) / 2.0)
	
	var pierce = 0
	if "farmer_scythe_pierce" in player and get_parent().GameManager.game_data["skin"] == "farmer":
		pierce = player.farmer_scythe_pierce
	elif "mage_pierce" in player and get_parent().GameManager.game_data["skin"] == "mage":
		pierce = player.mage_pierce
	
	for i in range(total_shots):
		var proj = get_projectile() 
		
		var proj_rotation = start_rotation + (i * spread_angle)
		var dir = Vector2.RIGHT.rotated(proj_rotation)
		
		if proj.has_method("activate") and proj.get_method_argument_count("activate") > 4:
			proj.activate(shooting_point.global_position, proj_rotation, dir, base_damage, player, pierce)
		else:
			proj.activate(shooting_point.global_position, proj_rotation, dir, base_damage)
