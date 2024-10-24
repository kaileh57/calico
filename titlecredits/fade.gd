extends Node2D

@onready var animation_player = $UI/AnimationPlayer

@export var title: PackedScene

func _ready():
	$"/root/Music".play_music("res://sounds/music/CalicoDescentMainTitle.mp3", 0, true)

func transition():
	get_tree().change_scene_to_packed(title)

func _input(_event):
	if Input.is_action_pressed("Jump"):
		transition()
