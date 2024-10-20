extends Node3D

@onready var character = $Character
@onready var cam = character.CAMERA
var auth := false

@onready var username = $Character/Username

# Called when the node enters the scene tree for the first time.
func _ready():
	auth = is_multiplayer_authority()
	cam.current = auth
	character.immobile = !auth
	character.jumping_enabled = auth
	character.pausing_enabled = false
	character.crouch_enabled = auth
	character.sprint_enabled = auth
	if auth:
		username.text = $"/root/MultiplayerData".username
		username.visible = false


func _enter_tree():
	#Sets the person in control of this player to it's id/the id of the person controlling
	set_multiplayer_authority(name.to_int())

func _physics_process(_delta):
	if auth:
		update_pos.rpc(character.position, character.velocity)

@rpc("authority", "call_remote", "unreliable")
func update_pos(pos, vel):
	character.position = pos
	character.velocity = vel
