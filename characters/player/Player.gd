extends CharacterBody2D

# --- REFERENCIAS A NODOS ---
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var weapon_pivot = $WeaponPivot
@onready var hud = $HUD

var warlock_soul_reaper: bool = false
var mage_pierce: int = 0
var farmer_scythe_size_multiplier: float = 1.0

# --- ATAQUE DE CLASES/SKINS ---
@onready var warlock_aura = $WarlockAura
@onready var aura_tick_timer = $WarlockAura/AuraTickTimer
@onready var shoot_timer = $Timer
@onready var erudit_book = $OrbitingBook

# --- PROPIEDADES ---
@export_group("Stats")
@export var speed: float = 300.0
@export var acceleration: float = 50.0
@export var friction: float = 20.0

@export_group("Health Stats")
@export var max_hp: int = 100
var current_hp: int = 100
var is_invincible: bool = false
var heal_cooldown: float = 0.0
var regen_active: bool = false
var regen_timer: float = 0.0

@export_group("RPG Stats")
@export var level: int = 1
@export var current_xp: int = 0
var total_xp_earned: int = 0
@export var xp_required: int = 100

@export_group("Combat Stats")
@export var attack_damage: int = 10
var damage_multiplier: float = 1.0

@export var additional_projectiles: int = 0
var card1_choice: String = ""
var time_elapsed: int = 0

# --- NUEVOS MODIFICADORES GLOBALES ---
var move_speed_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var damage_reduction: int = 0
var xp_pickup_multiplier: float = 1.0

var card3_choice: String = ""

# --- VARIABLES DEL ERUDITO ---
var erudit_book_count: int = 1
var erudit_orbit_speed: float = 3.0
var erudit_orbit_radius: float = 160.0
var erudit_current_angle: float = 0.0
var erudit_knockback_multiplier: float = 1.0
var active_books: Array = []
var erudit_hit_cooldowns: Dictionary = {}

# --- VARIABLES DEL CAMPESINO ---
var farmer_scythe_level: int = 0
var farmer_scythe_pierce: int = 0
var farmer_scythe_crit_chance: float = 0.0

# --- CHEATS ---
var secret_code_buffer: String = ""
var cheat_invincible: bool = false


func _ready():
	randomize()
	var my_skin = GameManager.game_data["skin"]
	setup_skin(my_skin)

	shoot_timer.timeout.connect(weapon_pivot.shoot)
	$GameTimer.timeout.connect(_on_game_timer_timeout)

	# Inicializar UI
	hud.initialize_stats(max_hp, xp_required)
	hud.upgrade_selected.connect(apply_upgrade)

	setup_word_ui()


func setup_skin(skin_id: String):
	var skin_path = "res://images/skins/" + skin_id + ".png"
	if ResourceLoader.exists(skin_path):
		sprite.texture = load(skin_path)

	var resource_path = "res://characters/player/" + skin_id + "_stats.tres"
	var stats: Resource = load(resource_path)
	if not stats:
		stats = load("res://characters/player/mage_stats.tres")

	if skin_id == "warlock":
		weapon_pivot.hide()
		shoot_timer.stop()
		warlock_aura.show()
		aura_tick_timer.start()
		erudit_book.hide()
		erudit_book.set_deferred("monitoring", false)

	elif skin_id == "erudit":
		warlock_aura.hide()
		aura_tick_timer.stop()
		weapon_pivot.hide()
		shoot_timer.stop()
		erudit_book.show()
		erudit_book.set_deferred("monitoring", true)
		setup_erudit_books()

	elif skin_id == "farmer":
		warlock_aura.hide()
		aura_tick_timer.stop()
		weapon_pivot.show()
		weapon_pivot.set_projectile("res://entities/projectiles/Scythe.tscn")
		shoot_timer.start()
		if erudit_book:
			erudit_book.hide()
			erudit_book.set_deferred("monitoring", false)

	else:
		warlock_aura.hide()
		aura_tick_timer.stop()
		weapon_pivot.show()
		weapon_pivot.set_projectile("res://entities/projectiles/Projectile.tscn")
		shoot_timer.start()
		if erudit_book:
			erudit_book.hide()
			erudit_book.set_deferred("monitoring", false)

	max_hp = stats.max_hp
	current_hp = max_hp
	speed = stats.speed
	acceleration = stats.acceleration
	attack_damage = stats.attack_damage
	additional_projectiles = stats.additional_projectiles


func _physics_process(delta):
	move_state()
	move_and_slide()
	update_visuals()
	if GameManager.game_data["skin"] == "erudit":
		update_erudit_orbit(delta)

	if heal_cooldown > 0:
		heal_cooldown -= delta

	if regen_active and current_hp < max_hp:
		regen_timer += delta
		if regen_timer >= 5.0:
			current_hp = mini(current_hp + 1, max_hp)
			hud.update_hp(current_hp)
			regen_timer = 0.0


func update_erudit_orbit(delta):
	erudit_current_angle += erudit_orbit_speed * delta
	if erudit_current_angle >= TAU:
		erudit_current_angle -= TAU

	var spacing = TAU / max(1, active_books.size())

	for i in range(active_books.size()):
		var book = active_books[i]
		var angle = erudit_current_angle + (i * spacing)
		var target_pos = Vector2(cos(angle), sin(angle)) * erudit_orbit_radius
		book.position = target_pos
		book.rotation = 0

		check_book_damage(book)

	update_erudit_cooldowns(delta)


func check_book_damage(book: Area2D):
	for body in book.get_overlapping_bodies():
		if (body.is_in_group("enemy") or body.is_in_group("obstacle")) and body.has_method("take_damage"):
			if not erudit_hit_cooldowns.has(body):
				body.take_damage(int(attack_damage * damage_multiplier))
				if body.has_method("apply_knockback"):
					var push_dir = global_position.direction_to(body.global_position)
					body.apply_knockback(push_dir, 300.0 * erudit_knockback_multiplier)
				erudit_hit_cooldowns[body] = 0.5


func update_erudit_cooldowns(delta: float):
	var keys_to_remove = []
	for enemy in erudit_hit_cooldowns.keys():
		if not is_instance_valid(enemy):
			keys_to_remove.append(enemy)
			continue

		erudit_hit_cooldowns[enemy] -= delta
		if erudit_hit_cooldowns[enemy] <= 0:
			keys_to_remove.append(enemy)

	for key in keys_to_remove:
		erudit_hit_cooldowns.erase(key)


func update_visuals():
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

	if velocity.length() > 0:
		animation_player.play("run")
	else:
		animation_player.play("idle")


func setup_erudit_books():
	for book in active_books:
		if is_instance_valid(book) and book != erudit_book:
			book.queue_free()
	active_books.clear()

	for i in range(erudit_book_count):
		add_new_book()


func add_new_book():
	if active_books.is_empty():
		active_books.append(erudit_book)
	else:
		var new_book = erudit_book.duplicate()
		add_child(new_book)
		new_book.show()
		active_books.append(new_book)


func move_state():
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var current_speed = speed * move_speed_multiplier
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * current_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)

# --- SISTEMA DE COMBATE Y RPG ---


func take_damage(amount: int):
	if is_invincible or cheat_invincible or current_hp <= 0:
		return
	
	# Tutorial mode: player is invincible
	if GameManager.is_tutorial_mode:
		return

	var actual_damage = max(1, amount - damage_reduction)
	current_hp -= actual_damage
	hud.update_hp(current_hp)

	if current_hp <= 0:
		die()
	else:
		is_invincible = true
		modulate = Color(1, 0, 0, 0.7)
		await get_tree().create_timer(0.5).timeout
		modulate = Color(1, 1, 1, 1)
		is_invincible = false


func gain_xp(amount: int):
	current_xp += amount
	total_xp_earned += amount
	hud.update_xp(current_xp)

	if current_xp >= xp_required:
		level_up()


func level_up():
	level += 1
	current_xp -= xp_required
	xp_required = int(xp_required * 1.5)

	hud.update_level(level, xp_required)
	hud.update_xp(current_xp)
	get_tree().paused = true
	MusicManager.lower_volume()

	# Opciones Generales (Carta 1)
	var pool_c1 = [
		{"id": "flat_dmg", "title": "FUERZA BRUTA", "desc": "Tus hechizos golpean más fuerte.", "stats": "+5 DAÑO"},
		{"id": "perc_dmg", "title": "PODER ARCANO", "desc": "Aumenta el daño total.", "stats": "+15% DAÑO"},
		{"id": "flat_spd", "title": "PIES LIGEROS", "desc": "Te mueves más rápido por el mapa.", "stats": "+30 VELOCIDAD"},
		{"id": "perc_spd", "title": "REFLEJOS", "desc": "Aumenta tu velocidad total.", "stats": "+10% VEL."},
		{"id": "atk_spd", "title": "METRALLETA", "desc": "Reduce el tiempo entre disparos.", "stats": "-15% RECARGA"},
		{"id": "armor", "title": "PIEL DE HIERRO", "desc": "Reduce el daño recibido.", "stats": "BLOQUEA 1 DAÑO"},
	]

	pool_c1.shuffle()
	var choice1 = pool_c1[0]
	card1_choice = choice1["id"]
	var data_c1 = {"title": choice1["title"], "desc": choice1["desc"], "stats": choice1["stats"]}

	var my_skin = GameManager.game_data["skin"]

	# Estructura de datos para la Carta 2
	var data_c2 = {}
	if my_skin == "warlock":
		if warlock_aura.scale.x < 3.0:
			data_c2 = {"title": "CORRUPCIÓN", "desc": "Tu aura oscura se expande.", "stats": "+15% RANGO"}
		elif aura_tick_timer.wait_time > 0.2:
			data_c2 = {"title": "VACÍO FAMÉLICO", "desc": "El aura ataca más rápido.", "stats": "-20% TICK"}
		else:
			data_c2 = {"title": "SEGADOR DE ALMAS", "desc": "Matar con el aura te cura.", "stats": "CURACIÓN"}

	elif my_skin == "erudit":
		if erudit_book_count < 6:
			data_c2 = {"title": "MÁS CONOCIMIENTO", "desc": "Añade un libro a tu órbita.", "stats": "+1 LIBRO"}
		elif erudit_orbit_speed < 8.0:
			data_c2 = {"title": "LECTURA RÁPIDA", "desc": "Tus libros giran más rápido.", "stats": "+30% VELOCIDAD"}
		else:
			data_c2 = {"title": "LIBROS PESADOS", "desc": "Los libros empujan más fuerte.", "stats": "+50% KNOCKBACK"}
	elif my_skin == "farmer":
		if farmer_scythe_level == 0:
			data_c2 = {"title": "GUADAÑA AFILADA", "desc": "Atraviesa 1 enemigo antes de volver.", "stats": "+1 PERFORACIÓN"}
		elif farmer_scythe_level == 1:
			data_c2 = {"title": "COSECHA MAGNA", "desc": "Las guadañas son más grandes.", "stats": "+30% TAMAÑO"}
		elif farmer_scythe_level == 2:
			data_c2 = {"title": "DOBLE GUADAÑA", "desc": "Lanza dos guadañas.", "stats": "+1 GUADAÑA"}
		elif farmer_scythe_level == 3:
			data_c2 = {"title": "SEGAR ALMAS", "desc": "Atraviesan infinitamente.", "stats": "PIERCE ∞"}
		else:
			data_c2 = {"title": "COSECHA CRÍTICA", "desc": "Posibilidad de golpe crítico.", "stats": "+15% PROB CRIT"}
	else:
		if additional_projectiles < 3:
			var total_bolas = additional_projectiles + 2
			data_c2 = {"title": "MULTICAST", "desc": "Añade un proyectil adicional.", "stats": str(total_bolas) + " BOLAS"}
		elif additional_projectiles == 3:
			data_c2 = {"title": "DISPARO PERFORANTE", "desc": "Los proyectiles atraviesan enemigos.", "stats": "+1 PIERCE"}
		else:
			data_c2 = {"title": "ARCHIMAGO", "desc": "Concentración de poder puro.", "stats": "+20% DAÑO TOTAL"}

	# Opciones de Supervivencia (Carta 3)
	var pool_c3 = [
		{"id": "rest", "title": "DESCANSO", "desc": "Recuperas salud y aumentas tu vitalidad.", "stats": "CURA 50%, +10 HP"},
		{"id": "regen", "title": "REGENERACIÓN", "desc": "Recuperas salud poco a poco.", "stats": "1 HP / 5s"},
	]

	pool_c3.shuffle()
	var choice3 = pool_c3[0]
	card3_choice = choice3["id"]
	var data_c3 = {"title": choice3["title"], "desc": choice3["desc"], "stats": choice3["stats"]}

	hud.show_level_up_panel(data_c1, data_c2, data_c3)


func apply_upgrade(choice: int):
	# Aplicar Mejoras Generales (Carta 1)
	if choice == 1:
		if card1_choice == "flat_dmg":
			attack_damage += 5
		elif card1_choice == "perc_dmg":
			damage_multiplier += 0.15
		elif card1_choice == "flat_spd":
			speed += 30
		elif card1_choice == "perc_spd":
			move_speed_multiplier += 0.10
		elif card1_choice == "atk_spd":
			attack_speed_multiplier -= 0.15
			if attack_speed_multiplier < 0.4:
				attack_speed_multiplier = 0.4
			shoot_timer.wait_time = max(0.1, shoot_timer.wait_time * 0.85)
		elif card1_choice == "armor":
			damage_reduction += 1

	# Aplicar Mejoras de Clase (Carta 2) - TODO en su mayor parte
	elif choice == 2:
		var my_skin = GameManager.game_data["skin"]
		if my_skin == "warlock":
			if warlock_aura.scale.x < 3.0:
				warlock_aura.scale *= 1.15
			elif aura_tick_timer.wait_time > 0.2:
				aura_tick_timer.wait_time *= 0.8
			else:
				warlock_soul_reaper = true
		elif my_skin == "erudit":
			if erudit_book_count < 6:
				erudit_book_count += 1
				add_new_book()
			elif erudit_orbit_speed < 8.0:
				erudit_orbit_speed *= 1.3
			else:
				erudit_knockback_multiplier = 1.5
				damage_multiplier += 0.10
		elif my_skin == "farmer":
			if farmer_scythe_level == 0:
				farmer_scythe_pierce = 1
				farmer_scythe_level = 1
			elif farmer_scythe_level == 1:
				farmer_scythe_size_multiplier = 1.3
				farmer_scythe_level = 2
			elif farmer_scythe_level == 2:
				additional_projectiles += 1
				farmer_scythe_level = 3
			elif farmer_scythe_level == 3:
				farmer_scythe_pierce = -1
				farmer_scythe_level = 4
			else:
				farmer_scythe_crit_chance += 0.15
		else:
			if additional_projectiles < 3:
				additional_projectiles += 1
			elif additional_projectiles == 3:
				mage_pierce = 1
				additional_projectiles = 4
			else:
				damage_multiplier += 0.20

	# Aplicar Mejoras de Supervivencia (Carta 3)
	elif choice == 3:
		if card3_choice == "rest":
			max_hp += 10
			current_hp = clampi(current_hp + (max_hp / 2), 0, max_hp)
		elif card3_choice == "regen":
			regen_active = true

		hud.initialize_stats(max_hp, xp_required)
		hud.update_hp(current_hp)

	hud.hide_level_up_panel()
	get_tree().paused = false
	MusicManager.restore_volume()

# --- SISTEMA DE PALABRAS ---


func setup_word_ui():
	var word = GameManager.target_word
	hud.setup_word(word)


func collect_letter(character: String) -> bool:
	var target_word = GameManager.target_word
	for i in range(target_word.length()):
		if target_word[i] == character:
			if hud.is_letter_empty(i):
				hud.set_letter(i, character)
				check_word_completed()
				return true
	return false


func check_word_completed():
	if hud.is_word_completed(GameManager.target_word):
		print("Player: Palabra lista. Emitiendo evento...")
		EventBus.word_completed.emit()


func clean_floor_letters():
	var letters_on_floor = get_tree().get_nodes_in_group("loot_letter")
	for letter in letters_on_floor:
		var tween = create_tween()
		tween.tween_property(letter, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(letter.deactivate)

# --- EVENTOS Y GAME OVER ---


func die():
	var sfx = AudioStreamPlayer.new()
	MusicManager.pause_music()
	sfx.stream = preload("res://music/game_over.mp3")
	sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx)
	sfx.play()
	get_tree().paused = true
	set_physics_process(false)
	weapon_pivot.set_physics_process(false)
	shoot_timer.stop()
	var death_canvas = CanvasLayer.new()
	death_canvas.layer = 100 
	var red_rect = ColorRect.new()
	red_rect.color = Color(0.8, 0, 0, 0)
	red_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_canvas.add_child(red_rect)
	add_child(death_canvas)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(red_rect, "color", Color(0.6, 0.0, 0.0, 0.7), sfx.stream.get_length())
	
	await sfx.finished
	EventBus.player_died.emit(total_xp_earned, int(time_elapsed))


func _on_game_timer_timeout():
	time_elapsed += 1
	var minutes = time_elapsed / 60.0
	var seconds = time_elapsed % 60
	hud.update_time(minutes, seconds)


func _on_aura_tick_timer_timeout() -> void:
	var enemies_in_aura = warlock_aura.get_overlapping_bodies()
	for body in enemies_in_aura:
		if body.has_method("take_damage") and not body.is_in_group("player"):
			var prev_hp = body.hp
			body.take_damage(int(attack_damage * damage_multiplier))
			if body.has_method("apply_knockback"):
				var push_dir = global_position.direction_to(body.global_position)
				body.apply_knockback(push_dir, 300.0)

			if warlock_soul_reaper and prev_hp > 0 and body.hp <= 0 and heal_cooldown <= 0.0:
				current_hp = mini(current_hp + 1, max_hp)
				hud.update_hp(current_hp)
				heal_cooldown = 2.0


func _on_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_button_pressed() -> void:
	get_tree().paused = true
	EventBus.exit_game_requested.emit()

# --- SISTEMA DE CÓDIGOS SECRETOS ---
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode_str = OS.get_keycode_string(event.keycode)
		if keycode_str.length() == 1 and keycode_str.to_upper() >= "A" and keycode_str.to_upper() <= "Z":
			secret_code_buffer += keycode_str.to_upper()
			
			if secret_code_buffer.length() > 20:
				secret_code_buffer = secret_code_buffer.substr(secret_code_buffer.length() - 20, 20)
				
			_check_secret_codes()

func _check_secret_codes():
	if secret_code_buffer.ends_with("GOD"):
		cheat_invincible = true
		current_hp = max_hp
		hud.update_hp(current_hp)
		modulate = Color(1.5, 1.5, 0.5, 1) 
		secret_code_buffer = ""
	
	elif secret_code_buffer.ends_with("LEVELUP"):
		gain_xp(xp_required - current_xp)
		secret_code_buffer = ""
		
	elif secret_code_buffer.ends_with("SONIC"):
		move_speed_multiplier *= 3.0
		modulate = Color(0.5, 0.5, 1.5, 1)
		secret_code_buffer = ""
		
	elif secret_code_buffer.ends_with("WORD"):
		var target_word = GameManager.target_word
		for i in range(target_word.length()):
			if hud.is_letter_empty(i):
				hud.set_letter(i, target_word[i])
		check_word_completed()
		secret_code_buffer = ""
