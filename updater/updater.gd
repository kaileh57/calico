extends CanvasLayer

func _input(event):
	if Input.is_action_just_pressed("Update"):
		update_game()

func update_game():
	var download_url = "https://www.dropbox.com/scl/fi/dahtabm7vzstd28v1kvd0/TestBuild.exe?rlkey=16tc91a2exzhqi8gzuu8v6lis&st=39ct98hg&dl=1"
	var current_exe_path = OS.get_executable_path()
	
	# Create Calico directory in AppData if it doesn't exist
	var appdata_path = OS.get_environment("APPDATA")
	var calico_path = appdata_path.path_join("Calico")
	DirAccess.make_dir_recursive_absolute(calico_path)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	print("Starting download...")
	var error = http_request.request(download_url)
	if error != OK:
		print("Error requesting download: ", error)
		return

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Download failed with error: ", result)
		return
	
	if body.size() == 0:
		print("Download failed: Empty file received")
		return
	
	print("Download completed. File size: ", body.size(), " bytes")
	
	var appdata_path = OS.get_environment("APPDATA")
	var calico_path = appdata_path.path_join("Calico")
	var new_exe_path = calico_path.path_join("new_version.exe")
	
	var file = FileAccess.open(new_exe_path, FileAccess.WRITE)
	file.store_buffer(body)
	file.close()
	
	print("New version saved to: ", new_exe_path)
	create_update_script(new_exe_path, OS.get_executable_path())
	print("Update script created. Closing game...")
	get_tree().quit()

func create_update_script(new_exe_path, current_exe_path):
	var script_content = """
@echo off
timeout /t 1 /nobreak > NUL
copy /Y "{new_exe}" "{current_exe}"
start "" "{current_exe}"
del "%~f0"
""".format({"new_exe": new_exe_path, "current_exe": current_exe_path})
	
	var appdata_path = OS.get_environment("APPDATA")
	var calico_path = appdata_path.path_join("Calico")
	var script_path = calico_path.path_join("update.bat")
	
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	file.store_string(script_content)
	file.close()
	
	# Note: The script execution is now handled by the game closing
