extends CanvasLayer

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton
@onready var volume_slider: HSlider = $CenterContainer/VBoxContainer/HBoxContainer/VolumeSlider
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

var master_bus_index: int

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	master_bus_index = AudioServer.get_bus_index("Master")
	
	if master_bus_index >= 0:
		volume_slider.value = AudioServer.get_bus_volume_db(master_bus_index)
		
	resume_button.pressed.connect(_on_resume_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	confirmation_dialog.confirmed.connect(_on_exit_confirmed)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused and not visible:
			return
			
		if visible:
			if confirmation_dialog.visible:
				confirmation_dialog.hide()
			else:
				_resume_game()
		else:
			_pause_game()

func _pause_game() -> void:
	get_tree().paused = true
	show()

func _resume_game() -> void:
	hide()
	get_tree().paused = false

func _on_resume_pressed() -> void:
	_resume_game()

func _on_exit_pressed() -> void:
	confirmation_dialog.popup_centered()

func _on_volume_changed(value: float) -> void:
	if master_bus_index >= 0:
		AudioServer.set_bus_volume_db(master_bus_index, value)

func _on_exit_confirmed() -> void:
	hide()
	EventBus.exit_game_requested.emit()
