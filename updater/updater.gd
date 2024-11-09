extends CanvasLayer

@onready var http_request = HTTPRequest.new()
@export var current_version = 0  # Changed to numeric version
@export var editor = true
var update_url = ""
var found_update = false

func _ready():
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)
    _on_timer_timeout()


func _on_timer_timeout():
    if found_update:
        return
    print("Checking for updates")
    var error = http_request.request("https://calicoapi.kellenhe.workers.dev")
    if error != OK:
        print("An error occurred in the HTTP request")

func _on_request_completed(result, _response_code, _headers, body):
    print(body.get_string_from_utf8())
    if result != HTTPRequest.RESULT_SUCCESS:
        print("Failed to get version info")
        return
        
    var json = JSON.parse_string(body.get_string_from_utf8())
    if json == null:
        print("Failed to parse response")
        return
        
    if json.has("version") and json.has("link"):
        var api_version = json["version"] # Now handles numeric version
        update_url = json["link"]
        
        if api_version > current_version:
            print("New version %s available at: %s" % [api_version, update_url])
            found_update = true
            download_update(update_url)

func download_update(link):
    if editor:
        print("Update check canceled: running in editor.")
        return
    
    var download_request = HTTPRequest.new()
    add_child(download_request)
    download_request.request_completed.connect(_on_download_completed)
    
    # Request the file download
    var headers = ["User-Agent: Godot"]
    var error = download_request.request(link, headers, HTTPClient.METHOD_GET)
    if error != OK:
        print("Failed to start download")

func _on_download_completed(result, _response_code, _headers, body):
    if result != HTTPRequest.RESULT_SUCCESS:
        print("Download failed")
        return
        
    # Get current exe path and convert to Windows format
    var current_path = OS.get_executable_path().replace("/", "\\")
    var base_dir = current_path.get_base_dir()
    var download_path = base_dir + "\\update.exe"
    var batch_path = base_dir + "\\update.bat"
    
    # Save downloaded file
    var file = FileAccess.open(download_path, FileAccess.WRITE)
    file.store_buffer(body)
    file.close()
    
    # Create batch script without logging
    var batch_content = """
@echo off
cd /d "%s"
timeout /t 2 /nobreak
copy /Y "%s" "%s"
if errorlevel 1 (
    exit /b 1
)
timeout /t 2 /nobreak
start "" "%s"
echo @echo off > cleanup.bat
echo timeout /t 5 /nobreak >> cleanup.bat
echo del /F /Q "%s" >> cleanup.bat
echo del /F /Q "%%~f0" >> cleanup.bat
echo del /F /Q cleanup.bat >> cleanup.bat
start /b "" cmd /c cleanup.bat
exit /b 0
""" % [base_dir, download_path, current_path, current_path, download_path]

    file = FileAccess.open(batch_path, FileAccess.WRITE)
    file.store_string(batch_content)
    file.close()
    
    # Run batch script
    # wait for a few seconds before running the batch script
    OS.delay_msec(2000)

    var thread = Thread.new()
    thread.start(OS.execute.bind("cmd.exe", ["/c", batch_path], false))
    get_tree().quit()