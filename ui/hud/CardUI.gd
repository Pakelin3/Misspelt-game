extends Button
class_name CardUI

signal card_selected(choice: int)

var data: Dictionary
var choice_index: int = 1
var custom_font = preload("res://fonts/Press_Start_2P/PressStart2P-Regular.ttf")

func _ready():
	apply_pixel_style()
	pressed.connect(_on_pressed)

func apply_pixel_style():
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#E6DCC6") 
	style_normal.border_width_bottom = 8 # Sombra fake
	style_normal.border_width_right = 8
	style_normal.border_width_left = 4
	style_normal.border_width_top = 4
	style_normal.border_color = Color("#3E261D") 
	style_normal.corner_radius_top_left = 0
	style_normal.corner_detail = 1
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color("#F2E9D8")
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color("#4B7B37")
	style_pressed.border_width_bottom = 4 
	style_pressed.border_width_right = 4
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", style_normal)

func setup(card_data: Dictionary, index: int):
	data = card_data
	choice_index = index
	text = "" 
	
	for child in get_children():
		child.queue_free()
	
	custom_minimum_size.x = 240 
	size_flags_vertical = Control.SIZE_EXPAND_FILL 
	
	var num_margin = MarginContainer.new()
	num_margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	num_margin.add_theme_constant_override("margin_top", 10)
	num_margin.add_theme_constant_override("margin_right", 10)
	num_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(num_margin)
	
	var num_label = Label.new()
	num_label.text = str(choice_index)
	num_label.add_theme_color_override("font_color", Color("#ffffffff"))
	num_label.add_theme_font_size_override("font_size", 16)
	num_label.add_theme_font_override("font", custom_font)
	num_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	num_margin.add_child(num_label)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT) 
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# -- TITULO --
	var title_lbl = Label.new()
	title_lbl.text = data.get("title", "")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_lbl.add_theme_color_override("font_color", Color("#3E261D"))
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_font_override("font", custom_font)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART 
	vbox.add_child(title_lbl)
	
	var line = HSeparator.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(line)

	# -- DESCRIPCIÓN --
	var desc_lbl = Label.new()
	desc_lbl.text = data.get("desc", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lbl.add_theme_color_override("font_color", Color("#5c4033")) 
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_font_override("font", custom_font)
	desc_lbl.custom_minimum_size.x = 100
	vbox.add_child(desc_lbl)
	
	# Espaciador
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	# -- STATS --
	var stat_lbl = Label.new()
	stat_lbl.text = data.get("stats", "")
	stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat_lbl.add_theme_color_override("font_color", Color("#4B7B37")) 
	stat_lbl.add_theme_font_size_override("font_size", 14)
	stat_lbl.add_theme_font_override("font", custom_font)
	vbox.add_child(stat_lbl)

	call_deferred("_update_min_size", margin)
	
func _update_min_size(margin: MarginContainer):
	var required_size = margin.get_combined_minimum_size()
	if required_size.y > custom_minimum_size.y:
		custom_minimum_size.y = required_size.y

func _on_pressed():
	print("CardUI: Click en Carta ", choice_index)
	emit_signal("card_selected", choice_index)
