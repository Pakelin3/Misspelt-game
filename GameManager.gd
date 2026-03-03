extends Node

# --- DATOS DE SESIÓN ---
var game_data = {
	"skin": "erudit",
	"token": "",
	"difficulty": 2
}

var mission_words: Array = [] 
var current_word_index: int = 0
var target_word: String = "LOADING" 
var found_letters: Array = []
var _js_window

# --- REFERENCIA CRÍTICA PARA WEB ---
var _js_callback_ref = null 

# --- SEMÁFORO  ---
var quiz_active: bool = false

func _ready():
	print("GameManager: Iniciando...")
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	EventBus.word_completed.connect(game_event_word_completed)
	EventBus.player_died.connect(send_game_over_to_web)
	EventBus.exit_game_requested.connect(send_exit_to_web)
	EventBus.spawn_punishment_boss.connect(_spawn_punishment_boss)
	
	if OS.has_feature("web"):
		_js_window = JavaScriptBridge.get_interface("window")
		_js_callback_ref = JavaScriptBridge.create_callback(_on_quiz_result_from_web)
		_js_window.godotQuizCallback = _js_callback_ref
		
	_load_web_parameters()

func _load_web_parameters():
	if OS.has_feature("web") and _js_window:
		var url_string = _js_window.location.href
		var params = _parse_url_params(url_string)
		if params.has("skin"): game_data["skin"] = params["skin"]
		if params.has("difficulty"): 
			game_data["difficulty"] = int(params["difficulty"])
		if params.has("words"):
			var raw_list = _js_window.decodeURIComponent(params["words"])
			mission_words = raw_list.split(",")
			
			var clean_words = []
			for w in mission_words:
				if w.length() > 1: clean_words.append(w)
			mission_words = clean_words
			
			if mission_words.size() > 0:
				current_word_index = 0
				set_target_word(mission_words[0])
			else:
				print("GameManager: Recibí lista vacía de palabras.")
				set_target_word("ERROR")
		else:
			mission_words = ["GODOT", "REACT", "FIX"]
			set_target_word("GODOT")

func _parse_url_params(url: String) -> Dictionary:
	var params = {}
	var query_start = url.find("?")
	if query_start == -1: return params
	var query = url.substr(query_start + 1)
	var pairs = query.split("&")
	for pair in pairs:
		var parts = pair.split("=")
		if parts.size() >= 2:
			params[parts[0]] = parts[1]
	return params

func set_target_word(word: String):
	target_word = word.to_upper()
	found_letters.clear()
	print("GameManager: Nueva misión -> ", target_word)

# --- FLUJO PRINCIPAL ---

func game_event_word_completed():
	if quiz_active: return
	print("GameManager: Palabra completada. Solicitando Quiz...")
	quiz_active = true 
	
	if OS.has_feature("web"):
		call_deferred("_pause_and_call_js")
	else:
		print("Modo Editor: Simulando Quiz ganado.")
		_on_quiz_result_from_web([true])

func _pause_and_call_js():
	get_tree().paused = true
	_js_window.triggerQuiz(target_word)


func send_game_over_to_web(final_xp: int, time_spent: int):
	print("GameManager: Enviando Game Over a React. XP:", final_xp, " Tiempo:", time_spent)
	if OS.has_feature("web") and _js_window:
		if _js_window.handleGameOver:
			_js_window.handleGameOver(final_xp, time_spent)
	else:
		print("GameManager (Editor): Game Over simulado.")

# --- MANEJO DE RESULTADOS DEL QUIZ ---
func _on_quiz_result_from_web(args):
	call_deferred("_handle_quiz_result_deferred", args)

func _handle_quiz_result_deferred(args):
	var success = false
	if args and args.size() > 0:
		success = args[0]
	
	var player = get_tree().get_first_node_in_group("player")
	if player: player.clean_floor_letters()
	
	quiz_active = false
	get_tree().paused = false 
	
	if success:
		if player: player.gain_xp(300)
	else:
		print("¡DERROTA! El jugador falló o cerró el quiz. INVOCANDO A LA Ñ...")
		EventBus.spawn_punishment_boss.emit() 
	
	if next_word():
		if player: player.setup_word_ui()
	else:
		game_win()

func _spawn_punishment_boss():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var boss_scene = preload("res://scenes/BossEnye.tscn")
	var boss = boss_scene.instantiate()
	
	var random_angle = randf() * TAU
	var spawn_distance = 600.0
	boss.global_position = player.global_position + Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	
	get_tree().current_scene.add_child(boss)
	
func send_exit_to_web():
	print("GameManager: Enviando Exit a React.")
	if OS.has_feature("web") and _js_window:
		if _js_window.handleExitGame:
			_js_window.handleExitGame()
	else:
		print("GameManager (Editor): Exit simulado.")


func next_word() -> bool:
	current_word_index += 1
	if current_word_index < mission_words.size():
		set_target_word(mission_words[current_word_index])
		return true 
	return false 

func game_win():
	print("¡MISIONES COMPLETADAS!")
	if OS.has_feature("web"):
		var player = get_tree().get_first_node_in_group("player")
		var final_xp = 0
		var final_time = 0
		
		if player: 
			final_xp = player.total_xp_earned
			final_time = int(player.time_elapsed)
		
		if _js_window.handleGameOver:
			_js_window.handleGameOver(final_xp, final_time)
	else:
		print("Ganaste (Editor)")
