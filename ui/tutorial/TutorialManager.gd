extends Node

# =============================================================================
# TutorialManager - Orquestador del Tutorial Interactivo de Misspelt
# Autoload que guía al jugador paso a paso por las mecánicas del juego.
# =============================================================================

enum Step {
	WELCOME,          # 0  - Pausa, bienvenida
	MOVEMENT,         # 1  - Despausado, espera movimiento
	ENEMIES_EXPLAIN,  # 2  - Pausa, spawn manual, explica enemigos
	COMBAT,           # 3  - Despausado, espera primer kill
	DROPS,            # 4  - Pausa, explica drops
	WORD_EXPLAIN,     # 5  - Pausa, explica barra de palabra
	COLLECT,          # 6  - Despausado, sigue spawneando, espera word complete
	WORD_DONE,        # 7  - Pausa, explica quiz
	LEVELUP_EXPLAIN,  # 8  - Pausa, explica level-up
	LEVELUP_PICK,     # 9  - Force level-up, espera selección de carta
	FINISH            # 10 - Mensaje final
}

# --- ESTADO ---
var is_active: bool = false
var current_step: int = -1
var total_steps: int = 11

# --- REFERENCIAS (descubiertas en runtime) ---
var player: CharacterBody2D
var spawner: Node2D
var hud: CanvasLayer

# --- UI DEL OVERLAY ---
var overlay_canvas: CanvasLayer
var dark_bg: ColorRect
var dialog_panel: PanelContainer
var title_label: Label
var desc_label: Label
var continue_btn: Button
var step_label: Label
var hint_panel: PanelContainer
var hint_label: Label

var custom_font: Font

# --- TRACKING ---
var initial_player_pos: Vector2 = Vector2.ZERO
var initial_kill_count: int = 0
var tutorial_spawn_timer: float = 0.0
var movement_timer: float = 0.0
var waiting_for_card: bool = false
var is_transitioning: bool = false


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if not GameManager.is_tutorial_mode:
		set_process(false)
		return
	
	custom_font = load("res://fonts/Press_Start_2P/PressStart2P-Regular.ttf")
	
	# Wait for the game scene to fully initialize
	await get_tree().create_timer(1.0).timeout
	
	_find_references()
	_build_overlay_ui()
	_connect_signals()
	
	# Disable pause menu during tutorial
	var pause_menu = get_tree().root.get_node_or_null("PauseMenu")
	if pause_menu:
		pause_menu.set_process_input(false)
	
	is_active = true
	_go_to_step(Step.WELCOME)


# =============================================================================
# DESCUBRIR REFERENCIAS
# =============================================================================
func _find_references():
	player = get_tree().get_first_node_in_group("player")
	
	# Find the EnemySpawner
	var spawners = get_tree().get_nodes_in_group("enemy_spawner")
	if spawners.size() > 0:
		spawner = spawners[0]
	
	if player:
		hud = player.get_node_or_null("HUD")


# =============================================================================
# CONECTAR SEÑALES
# =============================================================================
func _connect_signals():
	EventBus.word_completed.connect(_on_word_completed)
	
	if hud:
		hud.upgrade_selected.connect(_on_upgrade_selected)


# =============================================================================
# CONSTRUIR UI DEL OVERLAY (todo en código)
# =============================================================================
func _build_overlay_ui():
	overlay_canvas = CanvasLayer.new()
	overlay_canvas.layer = 90
	overlay_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay_canvas)
	
	# --- FONDO OSCURO ---
	dark_bg = ColorRect.new()
	dark_bg.color = Color(0, 0, 0, 0.65)
	dark_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_canvas.add_child(dark_bg)
	
	# --- PANEL DE DIÁLOGO (parte inferior) ---
	dialog_panel = PanelContainer.new()
	dialog_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_panel.anchor_top = 0.58
	dialog_panel.anchor_bottom = 0.96
	dialog_panel.anchor_left = 0.08
	dialog_panel.anchor_right = 0.92
	dialog_panel.offset_top = 0
	dialog_panel.offset_bottom = 0
	dialog_panel.offset_left = 0
	dialog_panel.offset_right = 0
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.12, 0.95)
	panel_style.border_color = Color(0.9, 0.75, 0.3)
	panel_style.set_border_width_all(4)
	panel_style.set_content_margin_all(24)
	dialog_panel.add_theme_stylebox_override("panel", panel_style)
	overlay_canvas.add_child(dialog_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog_panel.add_child(vbox)
	
	# Indicador de paso
	step_label = Label.new()
	step_label.add_theme_font_override("font", custom_font)
	step_label.add_theme_font_size_override("font_size", 9)
	step_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(step_label)
	
	# Título
	title_label = Label.new()
	title_label.add_theme_font_override("font", custom_font)
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title_label)
	
	# Descripción
	desc_label = Label.new()
	desc_label.add_theme_font_override("font", custom_font)
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Espaciador flexible
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Botón Continuar
	continue_btn = Button.new()
	continue_btn.text = "CONTINUAR  >"
	continue_btn.add_theme_font_override("font", custom_font)
	continue_btn.add_theme_font_size_override("font_size", 12)
	continue_btn.custom_minimum_size = Vector2(220, 44)
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.9, 0.75, 0.3)
	btn_normal.set_border_width_all(0)
	btn_normal.border_width_bottom = 4
	btn_normal.border_width_right = 4
	btn_normal.border_color = Color(0.6, 0.45, 0.1)
	btn_normal.set_content_margin_all(10)
	continue_btn.add_theme_stylebox_override("normal", btn_normal)
	
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(1.0, 0.85, 0.4)
	continue_btn.add_theme_stylebox_override("hover", btn_hover)
	
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = Color(0.7, 0.55, 0.15)
	btn_pressed.border_width_bottom = 2
	btn_pressed.border_width_right = 2
	continue_btn.add_theme_stylebox_override("pressed", btn_pressed)
	
	continue_btn.add_theme_color_override("font_color", Color(0.1, 0.08, 0.05))
	continue_btn.add_theme_color_override("font_hover_color", Color(0.1, 0.08, 0.05))
	continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_btn)
	
	# --- HINT PANEL (parte superior, para pasos de acción) ---
	hint_panel = PanelContainer.new()
	hint_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint_panel.anchor_left = 0.15
	hint_panel.anchor_right = 0.85
	hint_panel.anchor_top = 0.02
	hint_panel.anchor_bottom = 0.1
	hint_panel.offset_top = 0
	hint_panel.offset_bottom = 0
	
	var hint_style = StyleBoxFlat.new()
	hint_style.bg_color = Color(0.08, 0.06, 0.12, 0.85)
	hint_style.border_color = Color(0.4, 0.8, 0.4)
	hint_style.set_border_width_all(3)
	hint_style.set_content_margin_all(14)
	hint_panel.add_theme_stylebox_override("panel", hint_style)
	overlay_canvas.add_child(hint_panel)
	
	hint_label = Label.new()
	hint_label.add_theme_font_override("font", custom_font)
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_panel.add_child(hint_label)
	
	overlay_canvas.hide()


# =============================================================================
# FUNCIONES DE UI
# =============================================================================
func _show_dialog(title: String, desc: String, btn_text: String = "CONTINUAR  >"):
	dark_bg.show()
	dialog_panel.show()
	hint_panel.hide()
	title_label.text = title
	desc_label.text = desc
	continue_btn.text = btn_text
	step_label.text = "PASO %d / %d" % [current_step + 1, total_steps]
	overlay_canvas.show()


func _show_hint(text: String):
	dark_bg.hide()
	dialog_panel.hide()
	hint_label.text = text
	hint_panel.show()
	overlay_canvas.show()


func _hide_all():
	overlay_canvas.hide()


# =============================================================================
# MÁQUINA DE ESTADOS
# =============================================================================
func _go_to_step(step: int):
	current_step = step
	tutorial_spawn_timer = 0.0
	
	match step:
		Step.WELCOME:
			get_tree().paused = true
			_show_dialog(
				"BIENVENIDO A MISSPELT",
				"Aprende lo basico del juego en pocos pasos.\n\nTu mision: derrotar letras enemigas, recoger sus restos, y formar palabras correctas."
			)
		
		Step.MOVEMENT:
			get_tree().paused = false
			if player:
				initial_player_pos = player.global_position
			movement_timer = 0.0
			_show_hint("Usa WASD o las FLECHAS para moverte por el mapa")
		
		Step.ENEMIES_EXPLAIN:
			get_tree().paused = true
			# Spawn 3 enemies manually
			if spawner:
				for letter in ["H", "O", "L"]:
					spawner.spawn_tutorial_enemy(letter)
			_show_dialog(
				"LOS ENEMIGOS",
				"Estas letras te persiguen. Son los enemigos.\n\nTu heroe ataca de forma automatica. Esquiva sus ataques y derrotales para que suelten su letra."
			)
		
		Step.COMBAT:
			get_tree().paused = false
			initial_kill_count = GameManager.letters_killed
			_show_hint("Derrota al menos UN enemigo")
		
		Step.DROPS:
			get_tree().paused = true
			_show_dialog(
				"LOS DROPS",
				"Al derrotar un enemigo, suelta dos cosas:\n\n1. Su LETRA (brillante en el suelo)\n2. Una GEMA DE XP (experiencia)\n\nCamina sobre ellas para recogerlas."
			)
		
		Step.WORD_EXPLAIN:
			get_tree().paused = true
			_show_dialog(
				"LA MISION: FORMAR PALABRAS",
				"Mira la parte superior de la pantalla.\n\n" +
				"Tu mision es formar la palabra H-O-L-A. " +
				"Cada letra que recojas del suelo llena un espacio.\n\n" +
				"Cuando completes la palabra, aparecera un Quiz."
			)
		
		Step.COLLECT:
			get_tree().paused = false
			tutorial_spawn_timer = 0.0
			_show_hint("Derrota enemigos y recoge las letras para completar: H-O-L-A")
		
		Step.WORD_DONE:
			get_tree().paused = true
			_show_dialog(
				"PALABRA COMPLETADA",
				"En una partida real, al completar cada palabra aparecera un QUIZ para evaluar tu vocabulario.\n\nSi respondes bien ganas XP extra. Si fallas, un Jefe aparecera."
			)
		
		Step.LEVELUP_EXPLAIN:
			get_tree().paused = true
			_show_dialog(
				"SUBIR DE NIVEL",
				"Cada vez que tu barra de XP se llena subes de nivel.\n\n" +
				"Al subir, eliges UNA mejora entre 3 cartas:\n" +
				"- Carta 1: Mejora general\n" +
				"- Carta 2: Habilidad de tu clase\n" +
				"- Carta 3: Supervivencia"
			)
		
		Step.LEVELUP_PICK:
			# Force level up by giving enough XP
			if player:
				var needed = player.xp_required - player.current_xp
				player.gain_xp(needed)
			# The game is now paused by level_up() and cards are shown
			# Show hint on top of the cards
			_show_hint("Elige UNA de las 3 cartas de mejora (click o teclas 1, 2, 3)")
			waiting_for_card = true
		
		Step.FINISH:
			get_tree().paused = true
			_show_dialog(
				"LISTO PARA JUGAR",
				"Ya conoces las bases de Misspelt.\n\nElige tu heroe, selecciona la dificultad de palabras, y comienza tu primera partida real.\n\nBuena suerte, aventurero.",
				"ENTENDIDO"
			)


# =============================================================================
# PROCESS - Monitorear acciones del jugador
# =============================================================================
func _process(delta):
	if not is_active or is_transitioning:
		return
	
	match current_step:
		Step.MOVEMENT:
			if player:
				movement_timer += delta
				var dist = player.global_position.distance_to(initial_player_pos)
				if dist > 80.0 and movement_timer > 1.0:
					_go_to_step(Step.ENEMIES_EXPLAIN)
		
		Step.COMBAT:
			if GameManager.letters_killed > initial_kill_count:
				is_transitioning = true
				var timer = get_tree().create_timer(0.8)
				timer.timeout.connect(_on_combat_delay_done)
		
		Step.COLLECT:
			tutorial_spawn_timer += delta
			if tutorial_spawn_timer >= 2.5:
				tutorial_spawn_timer = 0.0
				if spawner:
					var word = "HOLA"
					var random_letter = word[randi() % word.length()]
					spawner.spawn_tutorial_enemy(random_letter)


func _on_combat_delay_done():
	is_transitioning = false
	_go_to_step(Step.DROPS)


func _on_word_delay_done():
	is_transitioning = false
	_go_to_step(Step.WORD_DONE)


func _on_upgrade_delay_done():
	is_transitioning = false
	_go_to_step(Step.FINISH)


# =============================================================================
# CALLBACKS
# =============================================================================
func _on_continue_pressed():
	match current_step:
		Step.WELCOME:
			_go_to_step(Step.MOVEMENT)
		Step.ENEMIES_EXPLAIN:
			_go_to_step(Step.COMBAT)
		Step.DROPS:
			_go_to_step(Step.WORD_EXPLAIN)
		Step.WORD_EXPLAIN:
			_go_to_step(Step.COLLECT)
		Step.WORD_DONE:
			_go_to_step(Step.LEVELUP_EXPLAIN)
		Step.LEVELUP_EXPLAIN:
			_go_to_step(Step.LEVELUP_PICK)
		Step.FINISH:
			_end_tutorial()


func _on_word_completed():
	if current_step == Step.COLLECT:
		is_transitioning = true
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(_on_word_delay_done)


func _on_upgrade_selected(_choice: int):
	if waiting_for_card:
		waiting_for_card = false
		is_transitioning = true
		var timer = get_tree().create_timer(0.3)
		timer.timeout.connect(_on_upgrade_delay_done)


# =============================================================================
# FINALIZAR TUTORIAL
# =============================================================================
func _end_tutorial():
	is_active = false
	_hide_all()
	
	# Re-enable pause menu
	var pause_menu = get_tree().root.get_node_or_null("PauseMenu")
	if pause_menu:
		pause_menu.set_process_input(true)
	
	get_tree().paused = false
	
	# Notify React
	GameManager.send_tutorial_complete_to_web()
	EventBus.tutorial_completed.emit()
