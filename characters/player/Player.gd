extends CharacterBody2D

# --- REFERENCIAS A NODOS ---
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var weapon_pivot = $WeaponPivot
@onready var hud = $HUD

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

@export_group("RPG Stats")
@export var level: int = 1
@export var current_xp: int = 0
var total_xp_earned: int = 0
@export var xp_required: int = 100

@export_group("Combat Stats")
@export var attack_damage: int = 10
@export var additional_projectiles: int = 0
var card1_choice: String = ""
var time_elapsed: int = 0

# --- VARIABLES DEL ERUDITO ---
var erudit_book_count: int = 1
var erudit_orbit_speed: float = 3.0
var erudit_orbit_radius: float = 160.0
var erudit_current_angle: float = 0.0
var active_books: Array = []
var erudit_hit_cooldowns: Dictionary = {}

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
		stats = load("res://characters/player/mage_stats.tres") # Fallback
		
	if skin_id == "warlock":
		weapon_pivot.hide()
		shoot_timer.stop() 
		warlock_aura.show()
		aura_tick_timer.start() 
		erudit_book.hide()
		erudit_book.set_deferred("monitoring", false) # <--- APAGAR COLISIÓN
		
	elif skin_id == "erudit":
		warlock_aura.hide()
		aura_tick_timer.stop()
		weapon_pivot.hide()
		shoot_timer.stop()
		erudit_book.show()
		erudit_book.set_deferred("monitoring", true) 
		setup_erudit_books()
		
	else:
		warlock_aura.hide()
		aura_tick_timer.stop()
		weapon_pivot.show()
		shoot_timer.start()
		if erudit_book:
			erudit_book.hide()
			erudit_book.set_deferred("monitoring", false)# <--- APAGAR COLISIÓN
		
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
				body.take_damage(attack_damage)
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
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)

# --- SISTEMA DE COMBATE Y RPG ---

func take_damage(amount: int):
	if is_invincible or current_hp <= 0: return
	
	current_hp -= amount
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
	
	var rand_stat = randi() % 3
	
	# Estructura de datos para la Carta 1
	var data_c1 = {}
	if rand_stat == 0:
		card1_choice = "damage"
		data_c1 = { "title": "FUERZA BRUTA", "desc": "Tus hechizos golpean más fuerte.", "stats": "+5 DAÑO" }
	elif rand_stat == 1:
		card1_choice = "speed"
		data_c1 = { "title": "PIES LIGEROS", "desc": "Te mueves más rápido por el mapa.", "stats": "+40 VELOCIDAD" }
	else:
		card1_choice = "attack_speed"
		data_c1 = { "title": "METRALLETA", "desc": "Reduce el tiempo entre disparos.", "stats": "-0.1s RECARGA" }
		
	var my_skin = GameManager.game_data["skin"]
	
	# Estructura de datos para la Carta 2
	var data_c2 = {}
	if my_skin == "warlock":
		data_c2 = { "title": "CORRUPCIÓN", "desc": "Tu aura oscura se expande.", "stats": "+15% RANGO" }
	elif my_skin == "erudit":
		if erudit_book_count < 6:
			data_c2 = { "title": "MÁS CONOCIMIENTO", "desc": "Añade un libro a tu órbita.", "stats": "+1 LIBRO" }
		else:
			data_c2 = { "title": "LECTURA RÁPIDA", "desc": "Tus libros giran más rápido.", "stats": "+ VELOCIDAD" }
	else:
		if additional_projectiles < 3:
			var total_bolas = additional_projectiles + 2 
			data_c2 = { "title": "MULTICAST", "desc": "Añade un proyectil adicional.", "stats": str(total_bolas) + " BOLAS" }
		else:
			data_c2 = { "title": "ARCHIMAGO", "desc": "Concentración de poder puro.", "stats": "+15 DAÑO" }

	# Estructura de datos para la Carta 3 (Curación)
	var data_c3 = { 
		"title": "DESCANSO", 
		"desc": "Recuperas salud y aumentas tu vitalidad.", 
		"stats": "+20 HP MÁX" 
	}
	
	hud.show_level_up_panel(data_c1, data_c2, data_c3)

func apply_upgrade(choice: int):
	if choice == 1:
		if card1_choice == "damage": attack_damage += 5
		elif card1_choice == "speed": speed += 40
		elif card1_choice == "attack_speed":
			if shoot_timer.wait_time > 0.15: shoot_timer.wait_time -= 0.1
	elif choice == 2:
		var my_skin = GameManager.game_data["skin"]
		if my_skin == "warlock":
			warlock_aura.scale *= 1.15 
			attack_damage += 2
		elif my_skin == "erudit":
			if erudit_book_count < 6:
				erudit_book_count += 1
				add_new_book() 
			else:
				erudit_orbit_speed += 1.5 
		else:
			if additional_projectiles < 3: additional_projectiles += 1
			else: attack_damage += 15
	elif choice == 3:
		max_hp += 20
		current_hp = max_hp
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
	get_tree().paused = true
	set_physics_process(false)
	weapon_pivot.set_physics_process(false)
	shoot_timer.stop()
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
			body.take_damage(attack_damage)

func _on_button_pressed() -> void:
	get_tree().paused = false 
	get_tree().reload_current_scene()

func _on_exit_button_pressed() -> void:
	get_tree().paused = true
	EventBus.exit_game_requested.emit()
