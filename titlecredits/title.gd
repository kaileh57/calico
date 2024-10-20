extends Node2D

@onready var play = $UI1/Play
@onready var nm = $UI1/Name
@onready var fade = $ColorRect/Fade
@onready var host = $UI1/Host
@onready var ip = $UI1/IP

@export var next_scene: PackedScene

func _ready():
	_on_ip_text_changed("")
	_on_name_text_changed("")
	fade.play("fade")


func _on_ip_text_changed(new_text):
	if new_text.length() >= 5:
		nm.show(); nm.editable = true
	else:
		nm.hide(); nm.editable = false


func _on_name_text_changed(new_text):
	if new_text.length() >= 3:
		play.show(); play.disabled = false
	else:
		play.hide(); play.disabled = true
	if new_text.to_lower() == "kaileh57":
		host.show(); host.disabled = false
	else:
		host.hide(); host.disabled = true


func _on_play_pressed():
	fade.play_backwards("fade")
	$"/root/MultiplayerData".ip = ip.text
	$"/root/MultiplayerData".username = nm.text
	$"/root/MultiplayerData".host = false
	get_tree().change_scene_to_packed(next_scene)


func _on_host_pressed():
	fade.play_backwards("fade")
	await get_tree().create_timer(0.5).timeout
	$"/root/MultiplayerData".ip = ip.text
	$"/root/MultiplayerData".username = nm.text
	$"/root/MultiplayerData".host = true
	get_tree().change_scene_to_packed(next_scene)
