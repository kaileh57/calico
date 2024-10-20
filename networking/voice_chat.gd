extends Node

@onready var mic = $Mic
var idx : int
var effect: AudioEffectCapture
@export var manager : Node3D
@export var output : AudioStreamPlayer3D
var playback : AudioStreamGeneratorPlayback
var buffer_size := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	set_multiplayer_authority(manager.get_multiplayer_authority()) 
	print(is_multiplayer_authority())
	if (is_multiplayer_authority()):
		mic.stream = AudioStreamMicrophone.new()
		mic.play()
		idx = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(idx, 5)
		print(effect)
	playback = output.get_stream_playback()


func _physics_process(_delta):
	if (not is_multiplayer_authority()): return
	buffer_size = effect.get_frames_available()
	if (effect.can_get_buffer(buffer_size) && playback.can_push_buffer(buffer_size)):
		send_data.rpc(effect.get_buffer(buffer_size))
	effect.clear_buffer()
	output.position = manager.character.position

# if not "call_remote," then the player will hear their own voice
# also don't try and do "unreliable_ordered." didn't work from my experience
@rpc("any_peer", "call_remote", "reliable")
func send_data(data : PackedVector2Array):
	for i in range(0,buffer_size):
		playback.push_frame(data[i])
