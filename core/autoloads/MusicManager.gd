extends Node

var level_player: AudioStreamPlayer
var boss_player: AudioStreamPlayer

var current_level_music: AudioStream
var boss_tracks: Array[AudioStream] = []

var normal_volume: float = 0.0
var lowered_volume: float = -15.0

var fade_duration: float = 1.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	level_player = AudioStreamPlayer.new()
	level_player.bus = "Master"
	add_child(level_player)
	
	boss_player = AudioStreamPlayer.new()
	boss_player.bus = "Master"
	add_child(boss_player)
	
	boss_tracks.append(preload("res://music/enye1.mp3"))
	boss_tracks.append(preload("res://music/enye2.mp3"))
	
	EventBus.spawn_punishment_boss.connect(_on_boss_spawned)
	EventBus.boss_enye_died.connect(_on_boss_died)
	
	if not level_player.finished.is_connected(level_player.play):
		level_player.finished.connect(level_player.play)
	if not boss_player.finished.is_connected(boss_player.play):
		boss_player.finished.connect(boss_player.play)
	
	call_deferred("_start_level_music")

func _start_level_music():
	var difficulty = GameManager.game_data.get("difficulty", 1)
	
	if difficulty == 1:
		current_level_music = preload("res://music/lvl1.mp3")
	elif difficulty == 2:
		current_level_music = preload("res://music/lvl2.mp3")
	else:
		current_level_music = preload("res://music/lvl3.mp3")
		
	level_player.stream = current_level_music
	level_player.volume_db = -80.0
	level_player.play()
	
	var tween = create_tween()
	tween.tween_property(level_player, "volume_db", normal_volume, fade_duration)

func lower_volume():
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(level_player, "volume_db", lowered_volume, 0.5)

func restore_volume():
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(level_player, "volume_db", normal_volume, 0.5)

func pause_music():
	level_player.stream_paused = true
	boss_player.stream_paused = true

func resume_music():
	level_player.stream_paused = false
	boss_player.stream_paused = false

func _on_boss_spawned():
	level_player.stop()
	
	randomize()
	boss_player.stream = boss_tracks[randi() % boss_tracks.size()]
	boss_player.volume_db = normal_volume
	boss_player.play()

func _on_boss_died():
	level_player.stream = current_level_music
	level_player.volume_db = -80.0
	level_player.play()
	
	var tween = create_tween()
	tween.parallel().tween_property(boss_player, "volume_db", -80.0, fade_duration)
	tween.parallel().tween_property(level_player, "volume_db", normal_volume, fade_duration)
	
	tween.tween_callback(boss_player.stop)
