extends Node

class_name MusicManager

@onready var main_player: AudioStreamPlayer = AudioStreamPlayer.new()
var current_fade_player: AudioStreamPlayer = null
var current_fade_tween: Tween = null

const CROSSFADE_DURATION: float = 2.0  # Adjust as needed

func _ready() -> void:
	# Set up main audio player
	add_child(main_player)
	main_player.bus = "Music"
	main_player.volume_db = 0

func play_music(file_path: String, from_position: float = 0.0, should_loop: bool = false) -> void:
	var new_stream = load(file_path)
	if not new_stream:
		push_error("Failed to load audio file: " + file_path)
		return
		
	# Set looping on the new stream
	if new_stream is AudioStream:
		new_stream.loop = should_loop
		
	# If no music is currently playing, just start it
	if not main_player.playing:
		main_player.stream = new_stream
		main_player.play(from_position)
		return
		
	# Create temporary player for crossfade
	var fade_player = AudioStreamPlayer.new()
	add_child(fade_player)
	fade_player.bus = "Music"
	fade_player.stream = new_stream
	fade_player.volume_db = -80  # Start silent
	fade_player.play(from_position)
	
	# Cancel any existing fade
	if current_fade_tween:
		current_fade_tween.kill()
	if current_fade_player:
		current_fade_player.queue_free()
	
	current_fade_player = fade_player
	
	# Create new tween for crossfade
	current_fade_tween = create_tween()
	current_fade_tween.set_parallel(true)
	
	# Fade out current music
	current_fade_tween.tween_property(main_player, "volume_db", -80.0, CROSSFADE_DURATION)
	# Fade in new music
	current_fade_tween.tween_property(fade_player, "volume_db", 0.0, CROSSFADE_DURATION)
	
	# When crossfade is complete
	current_fade_tween.finished.connect(func():
		# Swap the players
		main_player.stop()
		main_player.stream = fade_player.stream
		main_player.play(fade_player.get_playback_position())
		main_player.volume_db = 0
		
		# Clean up fade player
		fade_player.queue_free()
		current_fade_player = null
		current_fade_tween = null
	)

func stop_music() -> void:
	if current_fade_tween:
		current_fade_tween.kill()
	if current_fade_player:
		current_fade_player.queue_free()
		current_fade_player = null
	
	var stop_tween = create_tween()
	stop_tween.tween_property(main_player, "volume_db", -80.0, CROSSFADE_DURATION)
	stop_tween.finished.connect(func():
		main_player.stop()
		main_player.volume_db = 0
	)

func get_playback_position() -> float:
	return main_player.get_playback_position()
