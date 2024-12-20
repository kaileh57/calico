extends Node

# Properties from multiplayer.gd
@export var player_scene: PackedScene
@export var world_scene: PackedScene
var username: String
var server_ip: String
var server_port: int
var world: Node  # Reference to world node from multiplayer
var world_is_loaded = false

# Track players
var players = {}
var local_player_id: int

func _ready():
	# Get MultiplayerData singleton
	var data = $"/root/MultiplayerData"
	
	# Create world node if it doesn't exist
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	
	# Load world scene if provided
	if world_scene:
		print("Loading world scene...")
		var world_instance = world_scene.instantiate()
		world.add_child(world_instance)
		print("World scene loaded")
	
	# Setup networking
	var peer = ENetMultiplayerPeer.new()
	
	print("Connecting to: ", server_ip, ":", server_port)
	var error = peer.create_client(server_ip, server_port)
	
	if error != OK:
		print("Failed to connect: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	
	# Connect signals
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

@rpc("authority", "reliable") 
func notify_world_loaded():
	print("World loaded notification received")
	world_is_loaded = true
	# Unfreeze local player if we have one
	if players.has(local_player_id):
		print("Unfreezing local player")
		players[local_player_id].character.immobile = false

func _on_connected():
	print("Connected to server!")
	local_player_id = multiplayer.get_unique_id()
	
	# Make sure we have a valid world reference
	if !world:
		push_error("No world reference set!")
		return
	
	print("Creating local player with ID: ", local_player_id)
	# Create player but start frozen
	var player = player_scene.instantiate()
	player.name = str(local_player_id)
	world.add_child(player)
	player.character.immobile = true
	players[local_player_id] = player
	print("Registering with server...")
	
	# Then register with server
	rpc_id(1, "register_player", username)

func _on_server_disconnected():
	print("Disconnected from server!")
	get_tree().quit()

# Handle new player connections
@rpc
func sync_new_player(id: int, spawn_position: Vector3):
	if id != local_player_id:
		var player = player_scene.instantiate()
		player.name = str(id)
		world.add_child(player)
		players[id] = player

# Handle player disconnections
@rpc
func remove_player(id: int):
	if players.has(id):
		players[id].queue_free()
		players.erase(id)

# Handle username updates
@rpc
func sync_player_info(id: int, player_username: String):
	if players.has(id):
		players[id].username = player_username

# Send local player position to server
func _physics_process(_delta):
	if local_player_id and players.has(local_player_id):
		var player = players[local_player_id]
		rpc_id(1, "receive_player_state", player.position, player.velocity)

# Receive position updates from server
@rpc
func broadcast_player_state(player_id: int, position: Vector3, velocity: Vector3):
	if players.has(player_id) and player_id != local_player_id:
		players[player_id].position = position
		players[player_id].velocity = velocity

func disconnect_from_server():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
