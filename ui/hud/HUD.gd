extends CanvasLayer 

signal upgrade_selected(choice: int)

# --- REFERENCIAS HUD ---
@onready var xp_bar = $XPBar
@onready var level_label = $LevelLabel
@onready var hp_bar = $HPBar
@onready var game_over_panel = $GameOverPanel
@onready var level_up_panel = $LevelUpPanel
@onready var time_label = $TimeLabel
@onready var word_container = $WordContainer

@onready var card1 = $LevelUpPanel/HBoxContainer/Card1
@onready var card2 = $LevelUpPanel/HBoxContainer/Card2
@onready var card3 = $LevelUpPanel/HBoxContainer/Card3

var custom_font = preload("res://fonts/Press_Start_2P/PressStart2P-Regular.ttf")

func _ready():
	card1.set_script(preload("res://ui/hud/CardUI.gd"))
	card2.set_script(preload("res://ui/hud/CardUI.gd"))
	card3.set_script(preload("res://ui/hud/CardUI.gd"))
	
	card1._ready()
	card2._ready()
	card3._ready()
	
	card1.card_selected.connect(_on_card_selected)
	card2.card_selected.connect(_on_card_selected)
	card3.card_selected.connect(_on_card_selected)
	
	level_up_panel.hide()
	game_over_panel.hide()

func _on_card_selected(choice: int):
	emit_signal("upgrade_selected", choice)

func show_level_up_panel(data_c1: Dictionary, data_c2: Dictionary, data_c3: Dictionary):
	card1.setup(data_c1, 1)
	card2.setup(data_c2, 2)
	card3.setup(data_c3, 3)
	level_up_panel.show()

func hide_level_up_panel():
	level_up_panel.hide()

func update_level(level: int, new_max_xp: int):
	level_label.text = "NIVEL " + str(level)
	xp_bar.max_value = new_max_xp

func update_xp(current_xp: int):
	var tween = create_tween()
	tween.tween_property(xp_bar, "value", current_xp, 0.2)

func show_game_over():
	game_over_panel.show()
	
func initialize_stats(max_hp: int, max_xp: int):
	hp_bar.max_value = max_hp
	hp_bar.value = max_hp
	xp_bar.max_value = max_xp
	xp_bar.value = 0

func update_hp(current_hp: int):
	hp_bar.value = current_hp

func update_time(minutes: int, seconds: int):
	time_label.text = "%02d:%02d" % [minutes, seconds]

func setup_word(word: String):
	for child in word_container.get_children():
		child.queue_free()
	
	for i in range(word.length()):
		var char_str = word[i]
		var label = Label.new()
		label.name = "Letter_" + str(i)
		label.add_theme_font_size_override("font_size", 40)
		label.add_theme_font_override("font", custom_font) 
		
		if char_str == " " or char_str == "_":
			label.text = " " 
			label.custom_minimum_size = Vector2(30, 0)
		else:
			label.text = "_"
		word_container.add_child(label)

func is_letter_empty(index: int) -> bool:
	var label_node = word_container.get_child(index)
	return label_node.text == "_"

func set_letter(index: int, character: String):
	var label_node = word_container.get_child(index)
	label_node.text = character
	label_node.modulate = Color(0, 1, 0) 

func is_word_completed(target_word: String) -> bool:
	for i in range(word_container.get_child_count()):
		var label = word_container.get_child(i)
		var target_char = target_word[i]
		if target_char != " " and target_char != "_" and label.text == "_":
			return false
	return true


func _input(event):
	if level_up_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
				print("HUD: Tecla 1 presionada")
				emit_signal("upgrade_selected", 1)
			elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
				print("HUD: Tecla 2 presionada")
				emit_signal("upgrade_selected", 2)
			elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
				print("HUD: Tecla 3 presionada")
				emit_signal("upgrade_selected", 3)
