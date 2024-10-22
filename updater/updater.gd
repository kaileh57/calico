extends CanvasLayer

# Placeholder methods for error handling
func handle_api_error() -> void:
	print("Failed to fetch data from API.")
	# Insert specific logic for API failure if needed
	get_tree().quit()

func handle_missing_data_error() -> void:
	print("Missing version or download URL from API.")
	# Insert specific logic for missing data failure if needed
	get_tree().quit()

func handle_download_error(error_code: int) -> void:
	print("Error during download: ", error_code)
	# Insert specific logic for download failure if needed
	get_tree().quit()

# Trigger update on input
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Update"):
		update_game()

# Function to update the game
func update_game() -> void:
	var api_url: String = "https://api.kaileh.dev/calico"
	
	# Create an HTTPRequest instance
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)

	# Use the signal connection for async request
	http_request.request_completed.connect(self._on_api_request_completed)

	# Send request to the API to fetch version and download URL
	var error: int = http_request.request(api_url)
	if error != OK:
		handle_api_error()
		return

# Callback for handling API request completion
func _on_api_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		handle_api_error()
		return

	# Create a JSON instance to parse the response
	var json: JSON = JSON.new()
	var json_result = json.parse(body.get_string_from_utf8())
	if json_result.error != OK:
		handle_api_error()
		return

	var data: Dictionary = json_result.result
	var download_url: String = data.get("download_url", null)
	var version: int = data.get("version", null)

	# Check if the version and download URL exist
	if download_url == null or version == null:
		handle_missing_data_error()
		return

	print("Starting download for version: ", version)
	
	# Proceed to download the new version
	download_new_version(download_url)

# Function to download the new version of the executable
func download_new_version(download_url: String) -> void:
	# Create an HTTPRequest instance
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(self._on_download_completed)

	# Initiate the download request
	print("Starting download from: ", download_url)
	var error: int = http_request.request(download_url)
	if error != OK:
		handle_download_error(error)
		return

# Callback for handling download completion
func _on_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		handle_download_error(result)
		return

	if body.size() == 0:
		print("Download failed: Empty file received.")
		handle_download_error(result)
		return

	# Save the downloaded executable to the Calico folder in AppData
	print("Download completed. File size: ", body.size(), " bytes")

	var appdata_path: String = OS.get_environment("APPDATA")
	var calico_path: String = appdata_path.path_join("Calico")
	
	# Create an instance of DirAccess to check and create directories
	var dir_access: DirAccess = DirAccess.open(calico_path)
	if dir_access == null:
		dir_access = DirAccess.open(appdata_path) # Open base path
		var error = dir_access.make_dir_recursive(calico_path)
		if error != OK:
			print("Failed to create Calico directory.")
			handle_download_error(result)
			return

	var new_exe_path: String = calico_path.path_join("new_version.exe")

	# Save the file using FileAccess
	var file: FileAccess = FileAccess.open(new_exe_path, FileAccess.WRITE)
	file.store_buffer(body)
	file.close()

	print("New version saved to: ", new_exe_path)
	create_update_script(new_exe_path, OS.get_executable_path())
	print("Update script created. Closing game...")
	get_tree().quit()

# Function to create the update script
func create_update_script(new_exe_path: String, current_exe_path: String) -> void:
	var script_content: String = """
@echo off
timeout /t 1 /nobreak > NUL
copy /Y "{new_exe}" "{current_exe}"
start "" "{current_exe}"
del "%~f0"
""".format({"new_exe": new_exe_path, "current_exe": current_exe_path})
	
	var appdata_path: String = OS.get_environment("APPDATA")
	var calico_path: String = appdata_path.path_join("Calico")
	var script_path: String = calico_path.path_join("update.bat")

	# Save the script file using FileAccess
	var file: FileAccess = FileAccess.open(script_path, FileAccess.WRITE)
	file.store_string(script_content)
	file.close()
