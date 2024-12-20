extends Node

# Configuration
const PORT = 57570
const MAX_PLAYERS = 32

# Scene references
@export var player_scene: PackedScene
@export var world_scene: PackedScene

# Track connected players
var players = {}
var world

signal world_loaded

# Called when the node enters the scene tree for the first time.
func _ready():
    var data = $"/root/MultiplayerData"
    # Initialize networking
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_server(data.port, 32)  # Using port from MultiplayerData
    
    if error != OK:
        print("Failed to start server: ", error)
        return
        
    multiplayer.multiplayer_peer = peer
    print("Server started on port: ", data.port)
    
    # Connect signals
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    
    # Setup server world
    world = $ServerWorld
    if world_scene:
        var world_instance = world_scene.instantiate()
        world.add_child(world_instance)
        # Notify clients
        notify_world_loaded.rpc()
        # Emit local signal
        world_loaded.emit()
    
    if world_scene:
        var world_instance = world_scene.instantiate()
        $ServerWorld.add_child(world_instance)
        # Notify clients after world is ready
        notify_world_loaded.rpc()

func _on_peer_connected(id: int):
    print("Player connected: ", id)
    
    # Create server-side player instance
    var player = player_scene.instantiate()
    player.name = str(id)
    world.add_child(player)
    players[id] = player
    
    # Notify clients of new player
    sync_new_player.rpc(id, Vector3.ZERO) # Default spawn position

func _on_peer_disconnected(id: int):
    print("Player disconnected: ", id)
    
    # Remove player instance and notify clients
    if players.has(id):
        players[id].queue_free()
        players.erase(id)
        remove_player.rpc(id)

@rpc("authority", "reliable")
func sync_new_player(id: int, spawn_position: Vector3):
    pass # Clients will implement this

@rpc("authority", "reliable")
func remove_player(id: int):
    pass # Clients will implement this

@rpc("any_peer", "reliable")
func register_player(username: String):
    var id = multiplayer.get_remote_sender_id()
    if players.has(id):
        players[id].username = username
        sync_player_info.rpc(id, username)

@rpc("authority", "reliable")
func sync_player_info(id: int, username: String):
    pass # Clients will implement this

# Receive position updates from clients
@rpc("any_peer", "unreliable")
func receive_player_state(position: Vector3, velocity: Vector3):
    var id = multiplayer.get_remote_sender_id()
    if players.has(id):
        # Optional: Add validation here
        players[id].position = position
        players[id].velocity = velocity
        # Broadcast to other clients
        broadcast_player_state.rpc(id, position, velocity)

# Send position updates to clients
@rpc("authority", "unreliable")
func broadcast_player_state(player_id: int, position: Vector3, velocity: Vector3):
    # Update client-side player positions
    if player_id != multiplayer.get_unique_id() and players.has(player_id):
        players[player_id].position = position
        players[player_id].velocity = velocity

func _exit_tree():
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

@rpc("authority", "reliable")
func notify_world_loaded():
    pass # Clients will implement this

func shutdown():
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()
    queue_free()

func _physics_process(_delta):
    # Broadcast world state to clients
    for id in players:
        var player = players[id]
        if player and is_instance_valid(player):
            broadcast_player_state.rpc(id, player.position, player.velocity)
