extends Node

@onready var data = $"/root/MultiplayerData"
@export var player_scene: PackedScene
@export var world_scene: PackedScene

var client_scene = preload("res://networking/client/client.tscn")
var server_scene = preload("res://networking/server/server.tscn")

var client
var server

# Called when the node enters the scene tree for the first time.
func _ready():
    if data.host:
        setup_host()
    else:
        setup_client()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    pass

func setup_host():
    # Create server first
    server = server_scene.instantiate()
    add_child(server)
    server.player_scene = player_scene
    server.world_scene = world_scene
    
    # Then create client that connects locally
    setup_client("localhost")

func setup_client(override_ip = null):
    client = client_scene.instantiate()
    add_child(client)
    
    # Setup client properties
    client.player_scene = player_scene
    client.world_scene = world_scene
    client.username = data.username
    client.server_ip = override_ip if override_ip else data.ip
    client.server_port = data.port

    # Important: Client should use existing world node 
    client.world = $World

func _exit_tree():
    if client:
        client.disconnect_from_server()
    if server:
        server.shutdown()
