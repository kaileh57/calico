extends Node3D

@onready var data = $"/root/MultiplayerData"

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene

@export var scene_with_spawn: Node3D

func _ready():
	if data.host:
		host()
		print("host")
	else:
		join()
		print("join")

func host():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	
	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			var map_udp = upnp.add_port_mapping(57570, 57570, "calico_udp", "UDP", 86400)
			var map_tcp = upnp.add_port_mapping(57570, 57570, "calico_tcp", "TCP", 86400)
		
			if not map_udp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(57570, 57570, "", "UDP", 86400)
			if not map_tcp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(57570, 57570, "", "TCP", 86400)
	
	print(upnp.query_external_address())
	
	
	peer.create_server(data.port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()

func join():
	peer.create_client(data.ip, data.port)
	multiplayer.multiplayer_peer = peer


func add_player(id = 1):
	#instances the player, names it the id of the connecting person, and adds them to the scene
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child",player)

func exit_game(id):
	#disconnect smoothly and delete the player for everyone
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)


func del_player(id):
	#remotley delete the player from everyones game
	rpc("_del_player", id)

#let anyone call this and also call it here
@rpc("any_peer","call_local")
func _del_player(id):
	#queue free the node
	get_node(str(id)).queue_free()
