extends Node3D

@onready var data = $"/root/MultiplayerData"
var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
@export var scene_with_spawn: Node3D

func _ready():
	if data.host:
		host()
		print("Starting server")
	else:
		join()
		print("Joining as client")

func host():
	# Create server scene
	var server_scene = load("res://server/server.tscn")
	var server = server_scene.instantiate()
	
	# Add server as child of multiplayer node
	add_child(server)
	
	# Configure server properties
	server.player_scene = player_scene
	server.test_scene = scene_with_spawn
	
	# Connect as client to own server
	peer.create_client("localhost", data.port)
	multiplayer.multiplayer_peer = peer

func join():
	peer.create_client(data.ip, data.port)
	multiplayer.multiplayer_peer = peer

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id):
	var player = get_node_or_null(str(id))
	if player:
		player.queue_free()
