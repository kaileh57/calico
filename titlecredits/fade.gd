extends Node2D

@onready var animation_player = $UI/AnimationPlayer

@export var title: PackedScene

func transition():
	get_tree().change_scene_to_packed(title)

func _input(_event):
	if Input.is_action_pressed("Jump"):
		transition()
