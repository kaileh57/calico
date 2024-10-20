extends Node

# Variables
var can_update: bool = true # flag to allow updating
var update_time: bool = false
var version_url: String = "https://version.kaileh.dev/api"
var version_file_path: String = "res://updater/version.txt"

# Reference to the Afk node
@onready var afk_node: Node = $"../Afk"
@onready var notice = $"../Notice"



# This function runs every 10 seconds
func _on_timer_timeout() -> void:
	# Check if user is AFK and if updates are allowed
	if afk_node.is_afk and can_update and not update_time:
		check_versions()

# Async function to fetch version from API and compare with local version
func check_versions() -> void:
	var version_api: String = await fetch_version_from_api()
	var version_file: String = load_version_from_file()
	print("Checked:")
	print("Api " + version_api)
	print("File " + version_file)
	
	if version_api != version_file:
		update()

# Function to fetch version from API
func fetch_version_from_api() -> String:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(version_url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		return ""

	var result = await http_request.request_completed
	var response_code = result[1]
	var body = result[3]

	if response_code != 200:
		push_error("Failed to get data from the API.")
		return ""

	var response_body: String = body.get_string_from_utf8()
	http_request.queue_free()
	return response_body.strip_edges()

# Function to load version from a file using FileAccess
func load_version_from_file() -> String:
	if not FileAccess.file_exists(version_file_path):
		push_error("Version file does not exist.")
		return ""

	var file = FileAccess.open(version_file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open version file.")
		return ""

	var version = file.get_line()
	file.close()
	return version.strip_edges()

# Function to be implemented later
func update() -> void:
	# Blank for now
	update_time = true
	print("Out of date")
	notice.play()
