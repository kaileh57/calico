extends Node

# Time in seconds to be considered AFK
const AFK_TIMEOUT = 300

# Timer to track inactivity
var inactivity_timer = 0.0

# Active flag to determine AFK state
var is_afk = false

# Store last mouse position
var last_mouse_position = Vector2()

# Called when the node enters the scene tree for the first time
func _ready():
	set_process(true)  # Start processing input and time
	last_mouse_position = get_viewport().get_mouse_position()  # Initialize the last mouse position
	#print("Monitoring user activity...")

# Called every frame to monitor activity and detect AFK
func _process(delta):
	# Increment the inactivity timer
	inactivity_timer += delta
	
	# Check for any input events (keyboard, mouse click, etc.)
	if Input.is_anything_pressed():
		reset_timer()
	
	# Detect mouse movement by comparing positions
	var current_mouse_position = get_viewport().get_mouse_position()
	if current_mouse_position != last_mouse_position:
		reset_timer()
		last_mouse_position = current_mouse_position

	# Detect if the player is AFK based on inactivity timer
	if inactivity_timer >= AFK_TIMEOUT and not is_afk:
		on_afk_entered()
	
	# If user becomes active after being AFK
	if is_afk and inactivity_timer < AFK_TIMEOUT:
		on_afk_exited()

# Reset the inactivity timer and mark user as active
func reset_timer():
	inactivity_timer = 0
	if is_afk:
		on_afk_exited()

# Called when user enters AFK state
func on_afk_entered():
	is_afk = true
	#print("User is AFK")

# Called when user exits AFK state
func on_afk_exited():
	is_afk = false
	#print("User is active again")
