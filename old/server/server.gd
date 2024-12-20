extends Node

# Scenes to be loaded
@export var player_scene: PackedScene
@export var test_scene: PackedScene

# Server settings
const PORT = 57570
const MAX_PLAYERS = 32

# Track connected players
var players = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize server
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	
	if error != OK:
		print("Failed to start server: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	print("Server started on port: ", PORT)
	
	# Connect signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Load test scene
	if test_scene:
		var scene = test_scene.instantiate()
		add_child(scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_peer_connected(id: int):
	print("Player connected: ", id)
	
	# Create player instance
	var player = player_scene.instantiate()
	player.name = str(id)
	
	# Set player authority
	player.set_multiplayer_authority(id)
	
	# Add player to scene
	add_child(player)
	players[id] = player

func _on_peer_disconnected(id: int):
	print("Player disconnected: ", id)
	
	# Remove player instance
	if players.has(id):
		players[id].queue_free()
		players.erase(id)

@rpc("authority", "reliable")
func register_player(username: String):
	var id = multiplayer.get_remote_sender_id()
	if players.has(id):
		players[id].username = username
