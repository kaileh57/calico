extends Node

@onready var mic = $Mic
var idx : int
var effect: AudioEffectCapture
@export var manager : Node3D
@export var output : AudioStreamPlayer3D
var playback : AudioStreamGeneratorPlayback
var buffer_size := 0

# Noise gate variables
var input_threshold = 0.01  # Set an amplitude threshold
var time_below_threshold = 0.0  # Track how long the audio has been below the threshold
var hold_time = 0.2  # Hold time in seconds (500ms)
var is_mic_muted = false  # Track whether the mic is muted

# Called when the node enters the scene tree for the first time.
func _ready():
	set_multiplayer_authority(manager.get_multiplayer_authority()) 
	print(is_multiplayer_authority())
	if is_multiplayer_authority():
		mic.stream = AudioStreamMicrophone.new()
		mic.play()
		idx = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(idx, 6)
	playback = output.get_stream_playback()

func _physics_process(_delta):
	output.position = manager.character.position
	if not is_multiplayer_authority():
		return
	process_mic(_delta)

func process_mic(_delta):
	var stereo_data: PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	if stereo_data.size() > 0:
		var max_amplitude := 0.0
		
		# Calculate max amplitude from stereo channels
		for i in range(stereo_data.size()):
			var value = (stereo_data[i].x + stereo_data[i].y) / 2.0
			max_amplitude = max(abs(value), max_amplitude)  # Track the max amplitude

		# If max amplitude is below the threshold, start the hold timer
		if max_amplitude < input_threshold:
			time_below_threshold += _delta  # Accumulate time below threshold
			if time_below_threshold >= hold_time:
				mute_mic(true)  # Mute the mic if it's been below the threshold for 500ms
				return  # Exit if muted
		else:
			time_below_threshold = 0.0  # Reset timer if amplitude is above the threshold
			if is_mic_muted:
				mute_mic(false)  # Unmute if the amplitude goes above the threshold

		# Only push data if the mic is not muted
		if not is_mic_muted and playback.can_push_buffer(stereo_data.size()):
			send_data.rpc(stereo_data)

	effect.clear_buffer()

# Helper function to mute/unmute the mic based on volume
func mute_mic(mute):
	is_mic_muted = mute
	#if mute:
		#print("Microphone muted")
	#else:
		#print("Microphone unmuted")

# if not "call_remote," then the player will hear their own voice
@rpc("any_peer", "call_remote", "reliable")
func send_data(data : PackedVector2Array):
	for i in range(0, data.size()):
		playback.push_frame(data[i])  # Push Vector2 frames (stereo: left and right channels)
